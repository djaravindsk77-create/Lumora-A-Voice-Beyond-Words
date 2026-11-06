import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatting helpers with localised dates/times.
class AppFormatters {
  AppFormatters._();

  static String time(BuildContext? context, DateTime dt,
      {String? localeCode}) {
    final String locale = localeCode ?? _localeOf(context);
    return DateFormat.Hm(locale).format(dt);
  }

  static String date(BuildContext? context, DateTime dt,
      {String? localeCode}) {
    final String locale = localeCode ?? _localeOf(context);
    return DateFormat.yMMMd(locale).format(dt);
  }

  static String full(BuildContext? context, DateTime dt,
      {String? localeCode}) {
    final String locale = localeCode ?? _localeOf(context);
    return DateFormat.yMMMd(locale).add_Hm().format(dt);
  }

  /// 'Mon' style short weekday.
  static String weekday(BuildContext? context, DateTime dt,
      {String? localeCode}) {
    final String locale = localeCode ?? _localeOf(context);
    return DateFormat.E(locale).format(dt);
  }

  static String _localeOf(BuildContext? context) {
    if (context == null) return 'en';
    final Locale? locale = Localizations.maybeLocaleOf(context);
    return locale?.languageCode ?? 'en';
  }
}
