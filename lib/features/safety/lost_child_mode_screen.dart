import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../models/child_profile.dart';
import '../../providers/safety_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/speech/tts_service.dart';

/// Lost Child Mode: shows the child's name/avatar, a giant
/// "Please call my parent" button, the predefined help message and trusted
/// contact info. Location sharing is optional, consent-based, always
/// visible while active and manually disableable.
class LostChildModeScreen extends StatelessWidget {
  const LostChildModeScreen({super.key});

  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } on Exception {
      // Launching may be unsupported (e.g. desktop) - safe to ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SafetyProvider safety = context.watch<SafetyProvider>();
    final SessionProvider session = context.watch<SessionProvider>();
    final ChildProfile? child = session.child;

    return Scaffold(
      backgroundColor: AppColors.hcPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.shield, color: Colors.white, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.t('safety.lostMode'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    tooltip: l.t('safety.exitLostMode'),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      safety.exitLostMode();
                      Navigator.of(context).maybePop();
                    },
                  ),
                ],
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white24,
                child: Icon(Icons.face, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                child?.name ?? '',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                l.t('safety.callParent'),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 88,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.hcPrimary,
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 40),
                  label: Text(
                    l.t('safety.callNow'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: AppColors.hcPrimary),
                  ),
                  onPressed: () async {
                    FeedbackService.confirm();
                    await TtsService.instance
                        .speak(l.t('safety.callParent'));
                    final String? phone = safety.activeContacts.isEmpty
                        ? null
                        : safety.activeContacts
                            .firstWhere(
                              (c) => c.isPrimary,
                              orElse: () => safety.activeContacts.first,
                            )
                            .phone;
                    if (phone != null && phone.isNotEmpty) await _call(phone);
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Consent-based location sharing - visible when active.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      activeThumbColor: Colors.white,
                      title: Text(
                        l.t('safety.shareLocation'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: safety.sharingLocation,
                      onChanged: (bool v) {
                        if (v) {
                          final bool ok = safety.startLocationSharing();
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      l.t('safety.locationVisible'))),
                            );
                          }
                        } else {
                          safety.stopLocationSharing();
                        }
                      },
                    ),
                    if (safety.sharingLocation)
                      Text(
                        l.t('safety.locationOn'),
                        style: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.t('safety.contacts'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.white70),
                ),
              ),
              ...safety.activeContacts.take(3).map(
                    (c) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.person,
                          color: Colors.white70),
                      title: Text(c.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(c.phone,
                          style: const TextStyle(color: Colors.white70)),
                      trailing: IconButton(
                        icon: const Icon(Icons.call,
                            color: Colors.white),
                        onPressed: () => _call(c.phone),
                      ),
                    ),
                  ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
