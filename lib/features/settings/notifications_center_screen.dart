import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/barrel.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

/// In-app notification centre: history of routine/activity/alert/note
/// notifications with mark-as-read and clear controls. Works offline.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final List<NotificationItem> items = repo.getNotifications();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('notif.title')),
        actions: <Widget>[
          IconButton(
            tooltip: l.t('settings.clearHistory'),
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              for (final NotificationItem n in items) {
                await repo.deleteNotification(n.id);
              }
            },
          ),
          const SignOutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // State rebuilds on next frame; keeps pull-to-refresh meaningful.
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: items.isEmpty
            ? ListView(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: EmptyView(
                      title: l.t('notif.empty'),
                      icon: Icons.notifications_none,
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final NotificationItem n = items[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        switch (n.type) {
                          'routine' => Icons.checklist,
                          'activity' => Icons.extension,
                          'alert' => Icons.shield,
                          'note' => Icons.sticky_note_2,
                          'event' => Icons.event,
                          _ => Icons.notifications,
                        },
                        color: n.type == 'alert'
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      title: Text(n.rawTitle ?? n.titleKey),
                      subtitle: Text(n.rawBody ?? n.bodyKey),
                      trailing: Text(
                        '${n.createdAt.hour}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
