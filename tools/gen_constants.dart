// Generates the Dart and TypeScript copies of shared/constants.json
// (SPEC ENG-8), so the app and Functions can't drift.
//
//   dart run tools/gen_constants.dart          # write both files
//   dart run tools/gen_constants.dart --check  # exit 1 if either is stale (CI)
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const _source = 'shared/constants.json';
const _dartOut = 'lib/core/constants.g.dart';
const _tsOut = 'functions/src/shared/constants.ts';
const _header =
    'GENERATED from shared/constants.json by tools/gen_constants.dart. '
    'Do not edit.';

void main(List<String> args) {
  final check = args.contains('--check');
  final json =
      jsonDecode(File(_source).readAsStringSync()) as Map<String, dynamic>;
  final outputs = {_dartOut: _formatDart(_dart(json)), _tsOut: _ts(json)};

  var stale = false;
  outputs.forEach((path, content) {
    final file = File(path);
    final current = file.existsSync() ? file.readAsStringSync() : null;
    if (current == content) return;
    if (check) {
      print('$path is out of date. Run: dart run tools/gen_constants.dart');
      stale = true;
    } else {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
      print('Wrote $path');
    }
  });
  if (stale) exit(1);
}

/// Formats generated Dart the way `dart format` would, so CI's format check
/// and `--check` agree.
String _formatDart(String source) {
  final dir = Directory.systemTemp.createTempSync('gen_constants');
  try {
    final file = File('${dir.path}/constants.g.dart')
      ..writeAsStringSync(source);
    final result = Process.runSync('dart', ['format', file.path]);
    if (result.exitCode != 0) {
      throw StateError('dart format failed: ${result.stderr}');
    }
    return file.readAsStringSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

String _pascal(String s) => s[0].toUpperCase() + s.substring(1);

String _camel(String s) {
  final parts = s.split('_');
  return parts.first +
      parts.skip(1).map((p) => p.isEmpty ? '' : _pascal(p)).join();
}

String _dart(Map<String, dynamic> json) {
  final b = StringBuffer()
    ..writeln('// $_header')
    ..writeln(
      '// ignore_for_file: public_member_api_docs, constant_identifier_names',
    )
    ..writeln()
    ..writeln("const String idSeparator = '${json['idSeparator']}';")
    ..writeln(
      "const String inviteCodeAlphabet = '${json['inviteCodeAlphabet']}';",
    )
    ..writeln()
    ..writeln('/// Firestore collection names.')
    ..writeln('abstract final class Collections {');
  (json['collections'] as Map<String, dynamic>).forEach((k, v) {
    b.writeln("  static const String $k = '$v';");
  });
  b
    ..writeln('}')
    ..writeln()
    ..writeln('/// Limits shared with the server and security rules.')
    ..writeln('abstract final class Limits {');
  (json['limits'] as Map<String, dynamic>).forEach((k, v) {
    b.writeln('  static const int $k = $v;');
  });
  b
    ..writeln('}')
    ..writeln()
    ..writeln('/// The team colors (TEAM-1), as ARGB.')
    ..writeln('const List<int> teamColorValues = [');
  for (final hex in (json['teamColors'] as List).cast<String>()) {
    b.writeln('  0xFF${hex.substring(1).toUpperCase()},');
  }
  b
    ..writeln('];')
    ..writeln()
    ..writeln(
      '/// The reminder times an event can have, in minutes before (SCHED-3).',
    )
    ..writeln(
      'const List<int> reminderOffsetsMinutes = '
      '[${(json['reminderOffsetsMinutes'] as List).join(', ')}];',
    );

  (json['enums'] as Map<String, dynamic>).forEach((name, values) {
    final type = _pascal(name);
    b
      ..writeln()
      ..writeln('enum $type {');
    for (final v in (values as List).cast<String>()) {
      b.writeln("  ${_camel(v)}('$v'),");
    }
    b
      ..writeln('  ;')
      ..writeln()
      ..writeln('  const $type(this.value);')
      ..writeln()
      ..writeln('  /// The string stored in Firestore.')
      ..writeln('  final String value;')
      ..writeln()
      ..writeln('  static $type? tryParse(String? value) {')
      ..writeln('    for (final e in values) {')
      ..writeln('      if (e.value == value) return e;')
      ..writeln('    }')
      ..writeln('    return null;')
      ..writeln('  }')
      ..writeln('}');
  });
  _dartNotifyKinds(b, json);
  return b.toString();
}

/// The notification kind table (NOTIF-2) as a Dart map.
void _dartNotifyKinds(StringBuffer b, Map<String, dynamic> json) {
  final kinds = json['notifyKinds'] as Map<String, dynamic>?;
  if (kinds == null) return;
  b
    ..writeln()
    ..writeln('/// How a notification kind behaves (NOTIF-2).')
    ..writeln('class NotifyKindInfo {')
    ..writeln('  const NotifyKindInfo({')
    ..writeln('    required this.important,')
    ..writeln('    required this.pref,')
    ..writeln('    required this.center,')
    ..writeln('    required this.channel,')
    ..writeln('  });')
    ..writeln()
    ..writeln("  /// Pushes even at a team's \"Important only\" level.")
    ..writeln('  final bool important;')
    ..writeln()
    ..writeln('  /// The global switch that turns it off, if any (NOTIF-4).')
    ..writeln('  final NotificationPref? pref;')
    ..writeln()
    ..writeln('  /// Listed in the notification center (NOTIF-11).')
    ..writeln('  final bool center;')
    ..writeln('  final NotifyChannel channel;')
    ..writeln('}')
    ..writeln()
    ..writeln('const Map<NotifyKind, NotifyKindInfo> notifyKindInfo = {');
  kinds.forEach((name, v) {
    final info = v as Map<String, dynamic>;
    final pref = info['pref'] == null
        ? 'null'
        : 'NotificationPref.${_camel(info['pref'] as String)}';
    final kind = 'NotifyKind.${_camel(name)}';
    final channel = 'NotifyChannel.${_camel(info['channel'] as String)}';
    b.writeln(
      '  $kind: NotifyKindInfo(important: ${info['important']}, '
      'pref: $pref, center: ${info['center']}, channel: $channel),',
    );
  });
  b.writeln('};');
}

String _ts(Map<String, dynamic> json) {
  final b = StringBuffer()
    ..writeln('// $_header')
    ..writeln()
    ..writeln("export const ID_SEPARATOR = '${json['idSeparator']}';")
    ..writeln(
      "export const INVITE_CODE_ALPHABET = '${json['inviteCodeAlphabet']}';",
    )
    ..writeln()
    ..writeln('export const Collections = {');
  (json['collections'] as Map<String, dynamic>).forEach((k, v) {
    b.writeln("  $k: '$v',");
  });
  b
    ..writeln('} as const;')
    ..writeln()
    ..writeln('export const Limits = {');
  (json['limits'] as Map<String, dynamic>).forEach((k, v) {
    b.writeln('  $k: $v,');
  });
  b
    ..writeln('} as const;')
    ..writeln()
    ..writeln('export const TEAM_COLORS = [');
  for (final hex in (json['teamColors'] as List).cast<String>()) {
    b.writeln("  '$hex',");
  }
  b
    ..writeln('] as const;')
    ..writeln()
    ..writeln(
      'export const REMINDER_OFFSETS_MINUTES = '
      '[${(json['reminderOffsetsMinutes'] as List).join(', ')}] as const;',
    );
  (json['enums'] as Map<String, dynamic>).forEach((name, values) {
    final list = (values as List).cast<String>();
    b
      ..writeln()
      ..writeln(
        'export const ${name}Values = [${list.map((v) => "'$v'").join(', ')}] as const;',
      )
      ..writeln(
        'export type ${_pascal(name)} = (typeof ${name}Values)[number];',
      );
  });
  final kinds = json['notifyKinds'] as Map<String, dynamic>?;
  if (kinds != null) {
    b
      ..writeln()
      ..writeln(
        '/** How each notification kind behaves (NOTIF-2): pushes at "Important only", its global switch, center, channel. */',
      )
      ..writeln('export const NOTIFY_KINDS = {');
    kinds.forEach((name, v) {
      final info = v as Map<String, dynamic>;
      final pref = info['pref'] == null ? 'null' : "'${info['pref']}'";
      b.writeln(
        "  $name: { important: ${info['important']}, "
        'pref: $pref as NotificationPref | null, '
        "center: ${info['center']}, "
        "channel: '${info['channel']}' as NotifyChannel },",
      );
    });
    b.writeln('} as const;');
  }
  return b.toString();
}
