import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/barrel.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../services/notifications/notification_service.dart';
import '../../widgets/barrel.dart';

/// Reminders: school, therapy, meals, sleep, activities, appointments,
/// routine tasks and events. Medication reminders are simple
/// caregiver-controlled notes and clearly say they are not medical advice.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Future<void> _add() async {
    final AppL10n l = context.l10n;
    final TextEditingController title = TextEditingController();
    TimeOfDay time = TimeOfDay.now();
    String repeat = 'daily';

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setDialog) {
          return AlertDialog(
            title: Text(l.t('rem.add')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: title,
                  decoration:
                      InputDecoration(labelText: l.t('rem.name')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Text(l.t('rem.time')),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: ctx,
                          initialTime: time,
                        );
                        if (picked != null) {
                          setDialog(() => time = picked);
                        }
                      },
                      child: Text(time.format(ctx)),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: repeat,
                  decoration: InputDecoration(labelText: l.t('rem.repeat')),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                        value: 'once', child: Text('Once')),
                    DropdownMenuItem<String>(
                        value: 'daily', child: Text('Daily')),
                    DropdownMenuItem<String>(
                        value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (String? v) =>
                      setDialog(() => repeat = v ?? 'daily'),
                ),
              ],
            ),
            actions: <Widget>[
          SignOutButton(),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.t('common.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.t('common.save')),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || title.text.trim().isEmpty) return;
    if (!mounted) return;
    final LumoraRepository repo = LumoraRepository.instance;
    final String childId =
        context.read<SessionProvider>().child?.id ?? 'unknown';
    final DateTime now = DateTime.now();
    final Reminder reminder = Reminder(
      id: repo.local.newId(),
      childId: childId,
      title: title.text.trim(),
      category: 'routine',
      time: DateTime(now.year, now.month, now.day, time.hour, time.minute),
      repeat: repeat,
    );
    await repo.saveReminder(reminder);
    await NotificationService.instance.scheduleReminder(reminder);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final String childId =
        context.watch<SessionProvider>().child?.id ?? 'unknown';
    final List<Reminder> reminders = repo
        .getReminders()
        .where((Reminder r) => r.childId == childId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('rem.title'))),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-reminder',
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: reminders.isEmpty
                  ? EmptyView(
                      title: l.t('rem.none'),
                      icon: Icons.alarm,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reminders.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Reminder r = reminders[i];
                        final Color color =
                            AppColors.fromName(r.colorName);
                        final DateTime next =
                            r.nextOccurrence(DateTime.now());
                        return Card(
                          child: SwitchListTile(
                            value: r.enabled,
                            onChanged: (bool v) async {
                              await repo.saveReminder(
                                  r.copyWith(enabled: v));
                              if (mounted) setState(() {});
                            },
                            secondary: Icon(IconCatalog.of(r.iconKey),
                                color: color),
                            title: Text(r.title),
                            subtitle: Text(
                              '${l.t('rem.repeat')}: ${r.repeat} · '
                              '${next.hour}:${next.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.t('rem.medicationNote'),
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
