import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../models/barrel.dart';
import '../../providers/safety_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sign_out_button.dart';

/// Safety hub: emergency siren button, big HELP button, safety cards that
/// speak + notify + log, alert history with honest statuses and instructions.
class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  @override
  void initState() {
    super.initState();
    // Contacts/alerts must be loaded before an emergency can target them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final String? childId = context.read<SessionProvider>().child?.id;
      if (childId != null) {
        context.read<SafetyProvider>().load(childId);
      }
    });
  }

  static const List<({String key, IconData icon, String color})> _cards =
      <({String key, IconData icon, String color})>[
    (key: 'safety.lost', icon: Icons.location_off, color: 'red'),
    (key: 'safety.callParent', icon: Icons.phone_in_talk, color: 'orange'),
    (key: 'safety.needHelp', icon: Icons.front_hand, color: 'red'),
    (key: 'safety.hurt', icon: Icons.healing, color: 'orange'),
    (key: 'safety.unsafe', icon: Icons.gpp_bad, color: 'purple'),
    (key: 'safety.unknownPerson', icon: Icons.person_off, color: 'gray'),
    (key: 'safety.goHome', icon: Icons.home, color: 'blue'),
    (key: 'safety.emergency', icon: Icons.emergency, color: 'red'),
  ];

  Future<void> _raise(BuildContext context, String messageKey) async {
    final AppL10n l = context.l10n;
    final SafetyProvider safety = context.read<SafetyProvider>();
    final SessionProvider session = context.read<SessionProvider>();
    FeedbackService.confirm();

    await safety.raiseAlert(
      childId: session.child?.id ?? 'unknown',
      messageKey: messageKey,
      spokenText: l.t(messageKey),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('safety.helpPressed'))),
      );
    }
  }

  /// The one-tap emergency: confirm -> siren + location + SMS draft, and the
  /// whole screen flashes bright red/white while the siren is on.
  ///
  /// The confirm dialog also asks for location consent, so the alert actually
  /// carries the child's coordinates the first time the button is used
  /// (instead of silently sending without one).
  Future<void> _emergency(BuildContext context) async {
    final AppL10n l = context.l10n;
    final SafetyProvider safety = context.read<SafetyProvider>();
    final SessionProvider session = context.read<SessionProvider>();
    final SettingsProvider settings = context.read<SettingsProvider>();

    FeedbackService.confirm();

    final _EmergencyConfirmResult? result = await showDialog<
        _EmergencyConfirmResult>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => _EmergencyConfirmDialog(
        // Pre-ticked once consent exists; asked for explicitly the first time.
        consentAlreadyGiven: settings.settings.locationConsent,
      ),
    );
    if (result == null || !result.start || !context.mounted) return;

    // Record the consent the user just gave so later alerts default to
    // including the location (and so the privacy screen reflects it).
    if (result.shareLocation) {
      await settings.setLocationConsent(true);
    }

    // Pass the user's actual choice through so the emergency uses what
    // they agreed to rather than silently re-deriving it from consent state.
    final bool shareLoc = result.shareLocation;

    await safety.emergency(
      childId: session.child?.id ?? 'unknown',
      childName: session.child?.name ?? 'Your child',
      shareLocation: shareLoc,
    );

    // If the siren never started, tell the user plainly rather than leaving
    // them staring at a silent EMERGENCY button.
    if (!safety.sirenOn && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Row(
            children: <Widget>[
              const Icon(Icons.volume_off, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.t('safety.noSoundYet'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SafetyProvider safety = context.watch<SafetyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('safety.title')),
        actions: <Widget>[
          IconButton(
            tooltip: l.t('safety.contacts'),
            icon: const Icon(Icons.contacts),
            onPressed: () => context.push('/trusted-contacts'),
          ),
          const SignOutButton(),
        ],
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<SafetyProvider>().load(
                      context.read<SessionProvider>().child?.id ?? 'unknown'),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  const SizedBox(height: 12),
                  // ---- EMERGENCY: siren + location + contacts ----
                  _EmergencyButton(
                    sirenOn: safety.sirenOn,
                    busy: safety.emergencyBusy,
                    onTap: safety.emergencyBusy
                        ? null
                        : () => _emergency(context),
                  ),

                  // The flashing screen can be hidden while the siren keeps
                  // playing, so always keep a way to bring it back.
                  if (safety.sirenOn && safety.sirenFlashHidden) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      color: AppColors.error.withValues(alpha: 0.12),
                      child: ListTile(
                        leading: const Icon(Icons.visibility,
                            color: AppColors.error),
                        title: Text(l.t('safety.flashShow')),
                        subtitle: Text(l.t('safety.sirenOn')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: safety.showSirenFlash,
                      ),
                    ),
                  ],

                  // Dispatch result note (contacts reached, location attached).
                  if (safety.emergencyNote != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      child: Semantics(
                        label:
                            '${l.t('common.emergencyNote')} ${l.t(safety.emergencyNote!)}',
                        child: ListTile(
                          leading: const Icon(Icons.sms_outlined),
                          title: Text(l.t(safety.emergencyNote!)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: safety.clearEmergencyNote,
                          ),
                          onTap: safety.clearEmergencyNote,
                        ),
                      ),
                    ),
                    // What happened with the location, plus the coordinates so
                    // a caregiver can verify (or re-send) it by hand.
                    if (safety.locationNote != null)
                      Card(
                        color: safety.emergencyPosition != null
                            ? AppColors.success.withValues(alpha: 0.12)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    safety.emergencyPosition != null
                                        ? Icons.my_location
                                        : Icons.location_disabled,
                                    color: safety.emergencyPosition != null
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l.t(safety.locationNote!),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              if (safety.emergencyCoordinates != null) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  '${l.t('safety.locationLabel')}: '
                                  '${safety.emergencyCoordinates}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.map_outlined),
                                    label: Text(l.t('safety.openMaps')),
                                    onPressed: () => safety.openMapLink(
                                        safety.emergencyLink!),
                                  ),
                                ),
                              ],
                              if (safety.alertTextCopied) ...<Widget>[
                                const SizedBox(height: 8),
                                Text(
                                  l.t('safety.alertCopied'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                              // Permanently denied permission: point at settings.
                              if (safety.locationNote ==
                                  'emergency.locPermission') ...<Widget>[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.settings),
                                    label: Text(l.t('safety.openSettings')),
                                    onPressed: () => context
                                        .read<SafetyProvider>()
                                        .openLocationSettings(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 14),
                  // Big HELP button.
                  SizedBox(
                    width: double.infinity,
                    height: 104,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.emergency, size: 46),
                      label: Text(
                        l.t('safety.help'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      onPressed: () => _raise(context, 'safety.needHelp'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l.t('safety.cards'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 110,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (BuildContext context, int i) {
                      final card = _cards[i];
                      final Color color = AppColors.fromName(card.color);
                      return Semantics(
                        button: true,
                        label: l.t(card.key),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _raise(context, card.key),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: color.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(card.icon, size: 34, color: color),
                                const SizedBox(height: 6),
                                Text(
                                  l.t(card.key),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(l.t('safety.instructions'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        l.t('safety.instructionsBody'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.contacts),
                          label: Text(l.t('safety.contacts')),
                          onPressed: () => context.push('/trusted-contacts'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.science),
                          label: Text(l.t('safety.demoAlert')),
                          onPressed: () =>
                              _raise(context, 'safety.needHelp'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(l.t('safety.alertHistory'),
                      style: Theme.of(context).textTheme.titleMedium),
                  if (safety.alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l.t('safety.noAlerts'),
                          style: Theme.of(context).textTheme.bodySmall),
                    )
                  else
                    ...safety.alerts.take(5).map(
                          (SafetyAlert a) => Card(
                            child: ListTile(
                              leading: Icon(
                                switch (a.status) {
                                  'sent' => Icons.check_circle,
                                  'acknowledged' => Icons.verified,
                                  'failed' => Icons.error,
                                  _ => Icons.schedule,
                                },
                                color: a.status == 'failed'
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              title: Text(l.t(a.messageKey)),
                              subtitle: Text(
                                l.t('safety.${a.status}'),
                              ),
                              trailing: Text(
                                '${a.createdAt.day}/${a.createdAt.month}',
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    l.t('common.emergencyNote'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),

          // The flashing red/white emergency screen is provided app-wide by
          // SirenFlashHost (see app.dart), so it stays visible from every
          // screen while the siren sounds - with its own Stop/Hide actions.
        ],
      ),
    );
  }
}

/// Big red emergency button: icon on top, then EMERGENCY label, then subtitle.
/// Designed for a large tap target and clear urgency.
class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({
    required this.sirenOn,
    required this.busy,
    required this.onTap,
  });

  final bool sirenOn;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: Material(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          splashColor: Colors.white.withValues(alpha: 0.25),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  sirenOn ? Icons.notifications_active : Icons.campaign,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  l.t('safety.emergencyButton'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  l.t('safety.emergencySubtitle'),
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Outcome of the emergency confirm dialog.
class _EmergencyConfirmResult {
  const _EmergencyConfirmResult({
    required this.start,
    required this.shareLocation,
  });

  final bool start;
  final bool shareLocation;
}

/// A scrim + alert dialog used only for the emergency confirm step.
///
/// It also carries the location-sharing choice, so the alert can include the
/// child's coordinates without the user having to find a privacy setting.
class _EmergencyConfirmDialog extends StatefulWidget {
  const _EmergencyConfirmDialog({required this.consentAlreadyGiven});

  /// When consent is already recorded the checkbox starts ticked and is
  /// labelled accordingly.
  final bool consentAlreadyGiven;

  @override
  State<_EmergencyConfirmDialog> createState() => _EmergencyConfirmDialogState();
}

class _EmergencyConfirmDialogState extends State<_EmergencyConfirmDialog> {
  late bool _share;

  @override
  void initState() {
    super.initState();
    // Default to true: in a real emergency we want the location attached.
    _share = true;
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.error,
      titleTextStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      contentTextStyle: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Colors.white),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      title: Text(l.t('safety.emergencyConfirmTitle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.t('safety.emergencyConfirmBody')),
            const SizedBox(height: 8),
            // Explicit, in-context consent: shown on every emergency so the
            // user always knows whether the location is going out.
            Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  fillColor: WidgetStateProperty.all(Colors.white),
                  checkColor: WidgetStateProperty.all(AppColors.error),
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
              child: CheckboxListTile(
                value: _share,
                onChanged: (bool? v) => setState(() => _share = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  l.t('safety.shareLocationAlert'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white),
                ),
                subtitle: Text(
                  widget.consentAlreadyGiven
                      ? l.t('safety.shareLocationOn')
                      : l.t('safety.shareLocationOff'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context)
              .pop(const _EmergencyConfirmResult(
                start: false,
                shareLocation: false,
              )),
          child: Text(l.t('common.cancel')),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.error,
          ),
          icon: const Icon(Icons.notifications_active),
          label: Text(l.t('safety.emergencyButton')),
          onPressed: () => Navigator.of(context).pop(
            _EmergencyConfirmResult(start: true, shareLocation: _share),
          ),
        ),
      ],
    );
  }
}
