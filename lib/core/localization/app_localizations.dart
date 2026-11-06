import 'package:flutter/material.dart';

import 'l10n_en.dart';
import 'l10n_ta.dart';
import 'l10n_ml.dart';
import 'l10n_hi.dart';

/// Supported locales.
class AppLocales {
  AppLocales._();

  static const Locale english = Locale('en');
  static const Locale tamil = Locale('ta');
  static const Locale malayalam = Locale('ml');
  static const Locale hindi = Locale('hi');

  static const List<Locale> supported = <Locale>[
    english,
    tamil,
    malayalam,
    hindi,
  ];

  static String code(Locale l) => l.languageCode;

  static String displayName(Locale l) =>
      switch (l.languageCode) {
        'ta' => 'தமிழ்',
        'ml' => 'മലയാളം',
        'hi' => 'हिन्दी',
        _ => 'English',
      };

  static String languageName(String code) =>
      switch (code) {
        'ta' => 'Tamil',
        'ml' => 'Malayalam',
        'hi' => 'Hindi',
        _ => 'English',
      };

  /// Short label shown on the Child Home screen.
  static String childHomeLabel(String code) =>
      switch (code) {
        'ta' => 'தமிழ்',
        'ml' => 'മലയാളം',
        'hi' => 'हिन्दी',
        _ => 'English',
      };
}

/// Lightweight localisation for Lumora.
///
/// All user-facing strings live in `l10n_en.dart` / `l10n_ta.dart` and are
/// accessed in widgets via `context.l10n.someKey`. Adding a new language only
/// requires a new map plus registering it in [_maps].
class AppLocalizations {
  AppLocalizations._();

  static Map<String, String> _mapFor(String code) {      switch (code) {
      case 'ta':
        return l10nTa;
      case 'ml':
        return l10nMl;
      case 'hi':
        return l10nHi;
      case 'en':
      default:
        return l10nEn;
    }
  }


  /// The English fallback map, used when a key is missing from a language.
  static Map<String, String> get fallback => l10nEn;

  /// Translate [key] for [localeCode] with optional [params] substitution.
  /// Params are referenced as {name} in the strings.
  static String tr(
    String localeCode,
    String key, {
    Map<String, String>? params,
  }) {
    final Map<String, String> map = _mapFor(localeCode);
    String value = map[key] ?? fallback[key] ?? key;
    if (params != null) {
      params.forEach((String k, String v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }

  /// All keys (used by the demo translation helper and tests).
  static bool has(String key) => fallback.containsKey(key);
}

/// Convenience lookup on [BuildContext]: `context.l10n.homeTitle`.
extension L10nX on BuildContext {
  AppL10n get l10n {
    final Locale? locale = Localizations.maybeLocaleOf(this);
    final String code = locale?.languageCode ?? 'en';
    return AppL10n(code);
  }
}

/// Tiny typed handle so call sites read naturally: `l10n.t('home.title')`.
class AppL10n {
  const AppL10n(this.code);
  final String code;

  String t(String key, [Map<String, String>? params]) =>
      AppLocalizations.tr(code, key, params: params);
}
