// Lightweight static validation for Lumora (run: dart tool/validate_project.dart).
// Checks: brace/paren balance, import path resolution, route name wiring,
// localization key parity between l10n_en.dart and l10n_ta.dart.
import 'dart:io';

void main() {
  final List<String> errors = <String>[];
  final List<String> dartFiles = <String>[];
  void walk(String dir) {
    final Directory d = Directory(dir);
    if (!d.existsSync()) return;
    for (final FileSystemEntity e in d.listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.dart')) {
        dartFiles.add(e.path);
      }
    }
  }

  walk('lib');
  walk('test');
  walk('tool');

  // 1. Balance check (strings/comments stripped).
  final Map<String, String> stripped = <String, String>{};
  for (final String path in dartFiles) {
    final String src = File(path).readAsStringSync();
    stripped[path] = _strip(src);
    final int braces = '('.allMatches(stripped[path]!).length -
        ')'.allMatches(stripped[path]!).length;
    final int curlies = '{'.allMatches(stripped[path]!).length -
        '}'.allMatches(stripped[path]!).length;
    final int brackets = '['.allMatches(stripped[path]!).length -
        ']'.allMatches(stripped[path]!).length;
    if (braces != 0 || curlies != 0 || brackets != 0) {
      errors.add('$path unbalanced ( (): $braces  {}: $curlies  []: $brackets)');
    }
  }

  // 2. Relative import targets must exist.
  for (final String path in dartFiles) {
    final RegExp rel = RegExp(r'''import\s+['"]([^'"]+)['"]''');
    for (final RegExpMatch m in rel.allMatches(stripped[path]!)) {
      final String target = m.group(1)!;
      if (target.startsWith('dart:') || target.startsWith('package:')) continue;
      final Uri base = Uri.file(path);
      final File f = File(base.resolve(target).toFilePath());
      if (!f.existsSync()) {
        errors.add('$path: unresolved import "$target"');
      }
    }
  }

  // 3. Localization parity.
  final Set<String> enKeys = _stringLiterals('lib/core/localization/l10n_en.dart');
  final Set<String> taKeys = _stringLiterals('lib/core/localization/l10n_ta.dart');
  final Set<String> missingInTa = enKeys.difference(taKeys);
  if (missingInTa.isNotEmpty) {
    errors.add('l10n_ta.dart missing ${missingInTa.length} keys: '
        '${missingInTa.take(8).join(', ')}...');
  }

  // 4. Localization keys used via l10n.t('...') / l.t('...') must exist in EN.
  final RegExp keyUse = RegExp(r'''(?:l10n|l)\.t\(\s*['"]([a-zA-Z0-9_.]+)['"]''');
  final Set<String> used = <String>{};
  for (final String path in dartFiles) {
    for (final RegExpMatch m in keyUse.allMatches(stripped[path]!)) {
      used.add(m.group(1)!);
    }
  }
  final Set<String> unknownKeys = used.difference(enKeys).where(
    (String k) => !k.contains('\$'),
  ).toSet();
  if (unknownKeys.isNotEmpty) {
    errors.add('Localization keys used but not defined: $unknownKeys');
  }

  // 5. Routes referenced via context.go('/...') must exist in app_router.
  final String routerSrc = stripped['lib/core/routing/app_router.dart'] ?? '';
  final Set<String> routePaths = <String>{};
  final RegExp pathDecl = RegExp(r'''path:\s*['"]([^'"]+)['"]''');
  for (final RegExpMatch m in pathDecl.allMatches(routerSrc)) {
    routePaths.add(m.group(1)!);
  }
  final RegExp goUse = RegExp(r'''(?:go|pushReplacement)\(\s*['"](/[a-z0-9\-/]*)''');
  for (final String path in dartFiles) {
    for (final RegExpMatch m in goUse.allMatches(stripped[path]!)) {
      final String p = m.group(1)!;
      final bool matched = routePaths.contains(p) ||
          routePaths.any((String r) =>
              p.startsWith(r.split(':').first));
      if (!matched) {
        errors.add('$path: navigation to unknown route "$p"');
      }
    }
  }

  if (errors.isEmpty) {
    stdout.writeln('OK: ${dartFiles.length} Dart files validated.');
  } else {
    stdout.writeln('FAILED with ${errors.length} issue(s):');
    for (final String e in errors) {
      stdout.writeln(' - $e');
    }
    exitCode = 1;
  }
}

String _strip(String src) {
  final StringBuffer out = StringBuffer();
  bool inLineComment = false;
  bool inBlockComment = false;
  bool inString = false;
  String quote = '';
  for (int i = 0; i < src.length; i++) {
    final String c = src[i];
    final String next = i + 1 < src.length ? src[i + 1] : '';
    if (inLineComment) {
      if (c == '\n') inLineComment = false;
      continue;
    }
    if (inBlockComment) {
      if (c == '*' && next == '/') {
        inBlockComment = false;
        i++;
      }
      continue;
    }
    if (inString) {
      if (c == r'\') {
        i++;
        continue;
      }
      if (c == quote) inString = false;
      continue;
    }
    if (c == '/' && next == '/') {
      inLineComment = true;
      continue;
    }
    if (c == '/' && next == '*') {
      inBlockComment = true;
      continue;
    }
    if (c == '\'' || c == '"') {
      inString = true;
      quote = c;
      continue;
    }
    out.write(c);
  }
  return out.toString();
}

Set<String> _stringLiterals(String path) {
  final File f = File(path);
  if (!f.existsSync()) return <String>{};
  final String src = f.readAsStringSync();
  final RegExp lit = RegExp(r'''['"]([a-zA-Z0-9_.]+)['"]\s*:''');
  return lit.allMatches(src).map((RegExpMatch m) => m.group(1)!).toSet();
}
