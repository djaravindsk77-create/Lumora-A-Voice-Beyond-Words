import 'package:flutter/foundation.dart';

/// A caregiver-controlled reminder (school, therapy, meals, events...).
/// Medication reminders are simple caregiver-set notes, never medical advice.
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.childId,
    required this.title,
    required this.category,
    required this.time,
    this.date,
    this.repeat = 'daily',
    this.notificationEnabled = true,
    this.enabled = true,
    this.iconKey = 'alarm',
    this.colorName = 'blue',
    this.createdAt,
  });

  final String id;
  final String childId;

  /// school | therapy | meals | sleep | activities | appointments |
  /// routine | events | medication
  final String category;
  final String title;
  final DateTime time;
  final DateTime? date;

  /// once | daily | weekly
  final String repeat;
  final bool notificationEnabled;
  final bool enabled;
  final String iconKey;
  final String colorName;
  final DateTime? createdAt;

  Reminder copyWith({
    String? title,
    String? category,
    DateTime? time,
    DateTime? date,
    String? repeat,
    bool? notificationEnabled,
    bool? enabled,
    String? iconKey,
    String? colorName,
  }) =>
      Reminder(
        id: id,
        childId: childId,
        title: title ?? this.title,
        category: category ?? this.category,
        time: time ?? this.time,
        date: date ?? this.date,
        repeat: repeat ?? this.repeat,
        notificationEnabled:
            notificationEnabled ?? this.notificationEnabled,
        enabled: enabled ?? this.enabled,
        iconKey: iconKey ?? this.iconKey,
        colorName: colorName ?? this.colorName,
        createdAt: createdAt,
      );

  /// Next occurrence from [now], respecting [repeat].
  DateTime nextOccurrence(DateTime now) {
    DateTime candidate = DateTime(
      date?.year ?? now.year,
      date?.month ?? now.month,
      date?.day ?? now.day,
      time.hour,
      time.minute,
    );
    if (candidate.isAfter(now)) return candidate;
    switch (repeat) {
      case 'daily':
        candidate = candidate.add(const Duration(days: 1));
        break;
      case 'weekly':
        candidate = candidate.add(const Duration(days: 7));
        break;
      default:
        break;
    }
    return candidate;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'title': title,
        'category': category,
        'time': time.toIso8601String(),
        'date': date?.toIso8601String(),
        'repeat': repeat,
        'notificationEnabled': notificationEnabled,
        'enabled': enabled,
        'iconKey': iconKey,
        'colorName': colorName,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        childId: json['childId'] as String,
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? 'routine',
        time: DateTime.tryParse(json['time'] as String? ?? '') ??
            DateTime.now(),
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        repeat: json['repeat'] as String? ?? 'daily',
        notificationEnabled: json['notificationEnabled'] as bool? ?? true,
        enabled: json['enabled'] as bool? ?? true,
        iconKey: json['iconKey'] as String? ?? 'alarm',
        colorName: json['colorName'] as String? ?? 'blue',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
