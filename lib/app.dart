import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/barrel.dart';
import 'core/accessibility/tts_bridge.dart';
import 'services/emergency/siren_service.dart';
import 'services/speech/tts_service.dart';
import 'widgets/siren_flash_overlay.dart';

/// Lumora application root: wires providers, localisation, theming and
/// routing together.
class LumoraApp extends StatelessWidget {
  const LumoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final double textScale = settings.accessibility.textScale;
    final bool highContrast = settings.accessibility.highContrast;

    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<SessionProvider>(
          // Restores any persisted session: the user stays signed in across
          // restarts until they explicitly sign out.
          create: (_) => SessionProvider(settings)..restoreSession(),
        ),
        ChangeNotifierProvider<CommunicationProvider>(
          create: (_) => CommunicationProvider(settings),
        ),
        ChangeNotifierProvider<LearningProvider>(
          create: (_) => LearningProvider(settings),
        ),
        ChangeNotifierProvider<RoutineProvider>(
          create: (_) => RoutineProvider(settings),
        ),
        ChangeNotifierProvider<SafetyProvider>(
          create: (_) => SafetyProvider(settings),
        ),
      ],
      child: MaterialApp.router(
        title: 'Lumora',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: AppTheme.light(textScale: textScale, highContrast: highContrast),
        darkTheme:
            AppTheme.dark(textScale: textScale, highContrast: highContrast),
        themeMode: switch (settings.themeChoice) {
          ThemeChoice.light => ThemeMode.light,
          ThemeChoice.dark => ThemeMode.dark,
          ThemeChoice.system => ThemeMode.system,
        },
        locale: settings.locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (BuildContext context, Widget? child) {
          // Bind the TTS bridge once the widget tree is alive so provider
          // code can speak without importing plugin packages directly.
          TtsBridge.bind(
            speak: TtsService.instance.speak,
            stop: TtsService.instance.stop,
          );
          // Emergency siren spoken fallback (if asset playback ever fails).
          SirenService.ttsSpeak ??= TtsService.instance.speak;

          // The theme already scales every text style by the chosen
          // accessibility factor, so a large OS font size would multiply on
          // top of it and overflow fixed layouts (the yellow/black stripes).
          // Bound the combined effect so layouts stay intact.
          final MediaQueryData media = MediaQuery.of(context);
          final MediaQueryData guarded = media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 1.4),
          );
          // The flashing emergency screen wraps the whole app, so the siren
          // is visible (with a way out) from every screen, not just Safety.
          return MediaQuery(
            data: guarded,
            child: SirenFlashHost(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
