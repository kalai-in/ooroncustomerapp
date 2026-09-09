// ignore_for_file: avoid_print
//
// ─── apply_config.dart ──────────────────────────────────────────────────────
// Reads the active environment from
//   lib/core/configs/app_config.dart  →  static const String environment
// loads the matching `env/<environment>.json` file, then propagates its values
// into:
//   • lib/core/configs/app_config.dart       (BASE_URL, WEB_URL, SOCKET_BASE_URL,
//                                              DEEPLINK_SCHEME, DEEPLINK_HOST)
//   • android/app/src/main/AndroidManifest.xml   (deep link + app link <data>)
//   • ios/Runner/Info.plist                      (CFBundleURLSchemes custom scheme entry)
//
// Run from the project root after editing AppConfig.environment OR an env JSON:
//
//   dart run tool/apply_config.dart
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

void main() {
  final appConfig = File('lib/core/configs/app_config.dart');
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  final infoPlist = File('ios/Runner/Info.plist');

  if (!appConfig.existsSync()) _fail('AppConfig not found at ${appConfig.path}');
  if (!manifest.existsSync()) _fail('AndroidManifest not found at ${manifest.path}');
  if (!infoPlist.existsSync()) _fail('Info.plist not found at ${infoPlist.path}');

  // 1. Resolve active environment
  final src = appConfig.readAsStringSync();
  final environment = _readConst(src, 'environment');
  print('• environment    = $environment');

  // 2. Load env/<environment>.json
  final envFile = File('env/$environment.json');
  if (!envFile.existsSync()) {
    final available = Directory('env').existsSync()
        ? Directory('env').listSync().whereType<File>().map((f) => f.path).join(', ')
        : '(env/ folder missing)';
    _fail(
      'Env file not found: ${envFile.path}\n'
      '   AppConfig.environment is "$environment".\n'
      '   Available: $available',
    );
  }

  final json = jsonDecode(envFile.readAsStringSync()) as Map<String, dynamic>;
  final baseUrl = _readJson(json, 'BASE_URL', envFile.path);
  final webUrl = _readJson(json, 'WEB_URL', envFile.path);
  final socketBaseUrl = _readJson(json, 'SOCKET_BASE_URL', envFile.path);
  final scheme = _readJson(json, 'DEEPLINK_SCHEME', envFile.path);
  final host = _readJson(json, 'DEEPLINK_HOST', envFile.path);

  print('• BASE_URL        = $baseUrl');
  print('• WEB_URL         = $webUrl');
  print('• SOCKET_BASE_URL = $socketBaseUrl');
  print('• DEEPLINK_SCHEME = $scheme');
  print('• DEEPLINK_HOST   = $host');

  // 3. Patch every consumer
  _patchAppConfig(
    appConfig,
    baseUrl: baseUrl,
    webUrl: webUrl,
    socketBaseUrl: socketBaseUrl,
    scheme: scheme,
    host: host,
  );
  _patchManifest(manifest, scheme: scheme, host: host);
  _patchInfoPlist(infoPlist, scheme: scheme);

  print('\n✅ Synced "$environment" env into AppConfig + native files.');
  print('   Now run:  flutter clean && flutter run');
}

// ─── Readers ────────────────────────────────────────────────────────────────

/// Extracts `static const String <name> = '<value>';` from the AppConfig source.
String _readConst(String src, String name) {
  final pattern = RegExp(
    '''static\\s+const\\s+String\\s+$name\\s*=\\s*['"]([^'"]+)['"]\\s*;''',
  );
  final match = pattern.firstMatch(src);
  if (match == null) _fail('Constant `$name` not found in AppConfig');
  return match.group(1)!;
}

String _readJson(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    _fail('Key `$key` missing or empty in $path');
  }
  return value;
}

// ─── Writers ────────────────────────────────────────────────────────────────

void _patchAppConfig(
  File file, {
  required String baseUrl,
  required String webUrl,
  required String socketBaseUrl,
  required String scheme,
  required String host,
}) {
  final original = file.readAsStringSync();

  var patched = original;
  patched = _replaceConst(patched, 'baseUrl', baseUrl);
  patched = _replaceConst(patched, 'webUrl', webUrl);
  patched = _replaceConst(patched, 'socketBaseUrl', socketBaseUrl);
  patched = _replaceConst(patched, 'deeplinkScheme', scheme);
  patched = _replaceConst(patched, 'deeplinkHost', host);

  if (patched != original) {
    file.writeAsStringSync(patched);
    print('✓ Patched ${file.path}');
  } else {
    print('• ${file.path} already up to date');
  }
}

String _replaceConst(String src, String name, String value) {
  final pattern = RegExp(
    '''(static\\s+const\\s+String\\s+$name\\s*=\\s*['"])([^'"]*)(['"]\\s*;)''',
  );
  if (!pattern.hasMatch(src)) {
    _fail('Constant `$name` not found in AppConfig — cannot sync');
  }
  return src.replaceFirstMapped(
    pattern,
    (m) => '${m.group(1)}$value${m.group(3)}',
  );
}

/// Patches the custom-scheme `<data android:scheme="..."/>` deep link and the
/// `https` App Link `<data android:scheme="https" android:host="..." .../>`.
void _patchManifest(File file, {required String scheme, required String host}) {
  final original = file.readAsStringSync();
  var patched = original;
  var replacements = 0;

  final customScheme = RegExp(r'<data android:scheme="[^"]*"/>');
  patched = patched.replaceFirstMapped(customScheme, (m) {
    replacements++;
    return '<data android:scheme="$scheme"/>';
  });

  final appLink = RegExp(
    r'<data android:scheme="https" android:host="[^"]*"(\s+android:pathPrefix="[^"]*")?/>',
  );
  patched = patched.replaceAllMapped(appLink, (m) {
    replacements++;
    final pathPrefix = m.group(1) ?? '';
    return '<data android:scheme="https" android:host="$host"$pathPrefix/>';
  });

  if (replacements == 0) {
    _fail('No deep link <data> tags found in AndroidManifest.xml.');
  }

  if (patched != original) {
    file.writeAsStringSync(patched);
    print('✓ Patched $replacements entries in ${file.path}');
  } else {
    print('• ${file.path} already up to date');
  }
}

/// Replaces the custom-scheme `<string>` inside the SECOND `CFBundleURLSchemes`
/// array in Info.plist — the first array holds the Google Sign-In reversed
/// client ID and must be left untouched.
void _patchInfoPlist(File file, {required String scheme}) {
  final original = file.readAsStringSync();

  final blocks = RegExp(
    r'<key>CFBundleURLSchemes</key>\s*<array>\s*<string>[^<]*</string>\s*</array>',
    multiLine: true,
    dotAll: true,
  ).allMatches(original).toList();

  if (blocks.length < 2) {
    _fail(
      'Expected at least 2 `CFBundleURLSchemes` arrays in Info.plist '
      '(Google Sign-In + custom scheme), found ${blocks.length}.',
    );
  }

  final target = blocks[1];
  final replacement = target.group(0)!.replaceFirstMapped(
    RegExp(r'(<array>\s*<string>)[^<]*(</string>)'),
    (m) => '${m.group(1)}$scheme${m.group(2)}',
  );

  final patched = original.replaceRange(target.start, target.end, replacement);

  if (patched != original) {
    file.writeAsStringSync(patched);
    print('✓ Patched ${file.path}');
  } else {
    print('• ${file.path} already up to date');
  }
}

Never _fail(String msg) {
  stderr.writeln('❌ $msg');
  exit(1);
}
