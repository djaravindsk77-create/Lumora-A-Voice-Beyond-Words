import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../models/barrel.dart';
import '../../repositories/lumora_repository.dart';

/// Local notification service.
///
/// Notifications are stored as in-app [NotificationItem]s (the notification
/// centre works offline) and are additionally delivered as system
/// notifications when the plugin is available. Quiet hours and category
/// preferences are always respected.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool systemAvailable = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      tzdata.initializeTimeZones();
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      systemAvailable = true;
    } on Exception catch (e) {
      debugPrint('Local notifications unavailable ($e).');
      systemAvailable = false;
    }
  }

  /// Requests permission on Android 13+ / iOS. Safe no-op when unavailable.
  Future<bool> requestPermission() async {
    if (!systemAvailable) return false;
    try {
      final bool? granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    } on Exception {
      return false;
    }
  }

  bool _inQuietHours(AppSettings settings, DateTime now) {
    if (!settings.quietHoursEnabled) return false;
    final int minutes = now.hour * 60 + now.minute;
    final int start = settings.quietStartMinutes;
    final int end = settings.quietEndMinutes;
    if (start <= end) {
      return minutes >= start && minutes < end;
    }
    // Window crosses midnight.
    return minutes >= start || minutes < end;
  }

  /// Shows a notification if [type] is allowed by preferences and quiet
  /// hours, and records it in the in-app history regardless.
  Future<void> notify({
    required String type,
    required String title,
    required String body,
    AppSettings? settings,
    bool force = false,
  }) async {
    final AppSettings s = settings ?? const AppSettings();

    final bool categoryAllowed = switch (type) {
      'routine' => s.notifRoutine,
      'activity' => s.notifActivity,
      'alert' => s.notifAlerts,
      'note' => s.notifNotes,
      'event' => s.notifEvents,
      _ => true,
    };
    final bool allowed = force ||
        (categoryAllowed &&
            !_inQuietHours(s, DateTime.now()) &&
            !(type == 'alert' && false));

    final NotificationItem item = NotificationItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      titleKey: title,
      bodyKey: body,
      type: type,
      createdAt: DateTime.now(),
      rawTitle: title,
      rawBody: body,
    );
    await LumoraRepository.instance.saveNotification(item);

    if (!allowed || !systemAvailable) return;
    try {
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        'lumora_general',
        'Lumora notifications',
        channelDescription: 'Routines, activities, alerts and notes',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details = NotificationDetails(
        android: android,
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(item.id.hashCode & 0x7fffffff, title, body, details);
    } on Exception catch (e) {
      debugPrint('System notification failed ($e) - kept in history.');
    }
  }

  /// Schedules a zoned notification for a reminder (best effort).
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!systemAvailable || !reminder.notificationEnabled) return;
    try {
      final tz.TZDateTime when = tz.TZDateTime.from(
        reminder.nextOccurrence(DateTime.now()),
        tz.local,
      );
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        'lumora_reminders',
        'Lumora reminders',
        channelDescription: 'Scheduled reminders',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details = NotificationDetails(
        android: android,
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.zonedSchedule(
        reminder.id.hashCode & 0x7fffffff,
        reminder.title,
        reminder.title,
        when,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (e) {
      debugPrint('Scheduling failed ($e) - reminder kept in app.');
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    if (!systemAvailable) return;
    try {
      await _plugin.cancel(reminderId.hashCode & 0x7fffffff);
    } on Exception {
      // ignore
    }
  }
}
