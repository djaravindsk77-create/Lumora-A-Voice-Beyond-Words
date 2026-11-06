import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../providers/safety_provider.dart';
import '../providers/settings_provider.dart';

/// Wraps the whole app and covers it with a flashing red/white emergency
/// screen whenever the siren is sounding — from any screen, not just Safety.
///
/// The flash always offers a way out: stop the siren, or hide the flashing
/// screen while the siren keeps playing.
class SirenFlashHost extends StatelessWidget {
  const SirenFlashHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SafetyProvider safety = context.watch<SafetyProvider>();
    final bool showFlash = safety.sirenOn && !safety.sirenFlashHidden;

    return Stack(
      children: <Widget>[
        child,
        if (showFlash)
          Positioned.fill(
            child: SirenFlashOverlay(
              onStopSiren: safety.stopSiren,
              onHideFlash: safety.hideSirenFlash,
            ),
          ),
      ],
    );
  }
}

/// The full-screen flashing emergency screen itself. Public so it can be
/// rendered and verified on its own.
class SirenFlashOverlay extends StatefulWidget {
  const SirenFlashOverlay({
    super.key,
    required this.onStopSiren,
    required this.onHideFlash,
    this.gentle = false,
  });

  /// Stops the siren and ends the flash.
  final VoidCallback onStopSiren;

  /// Hides the flashing screen; the siren keeps playing.
  final VoidCallback onHideFlash;

  /// Slower, softer flash for users who prefer reduced motion.
  final bool gentle;

  @override
  State<SirenFlashOverlay> createState() => _SirenFlashOverlayState();
}

class _SirenFlashOverlayState extends State<SirenFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.gentle ? 900 : 320),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final bool reducedMotion =
        context.watch<SettingsProvider>().accessibility.reducedMotion;

    return Semantics(
      liveRegion: true,
      label: l.t('safety.flashTitle'),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          // Alternate between bright white and emergency red.
          final Color background = Color.lerp(
            Colors.white,
            AppColors.error,
            _controller.value,
          )!;
          return ColoredBox(color: background, child: child);
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.black.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.warning_amber_rounded,
                        size: 58, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      l.t('safety.flashTitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.t('safety.flashBody'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.volume_off, size: 28),
                        label: Text(
                          l.t('safety.flashStopSiren'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        onPressed: widget.onStopSiren,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        icon: const Icon(Icons.visibility_off),
                        label: Text(l.t('safety.flashHide')),
                        onPressed: widget.onHideFlash,
                      ),
                    ),
                    if (reducedMotion) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        l.t('a11y.reducedMotion'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
