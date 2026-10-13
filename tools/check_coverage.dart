// Checks line coverage of the domain and data layers (SPEC §8.1
// Maintainability: at least 80%). Runs in CI after `flutter test --coverage`.
//
//   dart run tools/check_coverage.dart [coverage/lcov.info] [--min=80]
//
// Counts every hand-written file under lib/features/*/domain/ and
// lib/features/*/data/ (not generated .g.dart or .freezed.dart files). A
// file no test loads isn't in lcov.info at all, so it would silently count
// as covered; the check fails on those and names them.
import 'dart:io';

final _layer = RegExp(r'^lib/features/[a-z_]+/(domain|data)/.+\.dart$');
final _generated = RegExp(r'\.(g|freezed)\.dart$');

/// Whether [path] (relative, with forward slashes) is counted.
bool counted(String path) =>
    _layer.hasMatch(path) && !_generated.hasMatch(path);

/// Whether Dart [source] has a function body, so its lines can be covered.
bool hasCode(String source) =>
    RegExp(r'=>|\)\s*(async\*?\s*|sync\*\s*)?\{|\bget\s+\w+\s*\{')
        .hasMatch(source);

/// Lines found and hit per counted file, from an lcov report.
Map<String, ({int found, int hit})> parseLcov(String lcov, {String root = ''}) {
  final result = <String, ({int found, int hit})>{};
  String? file;
  var found = 0;
  var hit = 0;
  for (final line in lcov.split('\n')) {
    if (line.startsWith('SF:')) {
      var path = line.substring(3).replaceAll(r'\', '/');
      if (root.isNotEmpty && path.startsWith(root)) {
        path = path.substring(root.length);
      }
      file = path.startsWith('/') ? path.substring(1) : path;
      found = 0;
      hit = 0;
    } else if (line.startsWith('DA:') && file != null) {
      found++;
      final count = int.tryParse(line.split(',')[1]) ?? 0;
      if (count > 0) hit++;
    } else if (line.trim() == 'end_of_record' && file != null) {
      if (counted(file)) result[file] = (found: found, hit: hit);
      file = null;
    }
  }
  return result;
}

void main(List<String> args) {
  final path = args.firstWhere(
    (a) => !a.startsWith('--'),
    orElse: () => 'coverage/lcov.info',
  );
  final min = double.parse(
    args
        .firstWhere((a) => a.startsWith('--min='), orElse: () => '--min=80')
        .substring(6),
  );
  final report = File(path);
  if (!report.existsSync()) {
    stderr.writeln('No $path: run flutter test --coverage first.');
    exit(1);
  }
  final root = '${Directory.current.path.replaceAll(r'\', '/')}/';
  final files = parseLcov(report.readAsStringSync(), root: root);

  final unloaded =
      [
            for (final f in Directory('lib/features').listSync(recursive: true))
              if (f is File) f.path.replaceAll(r'\', '/'),
          ]
          .where((p) => counted(p) && !files.containsKey(p))
          // Interfaces and freezed declarations have no lines to cover, so they
          // never show up in the report.
          .where((p) => hasCode(File(p).readAsStringSync()))
          .toList()
        ..sort();

  var found = 0;
  var hit = 0;
  final byLayer = <String, List<int>>{};
  for (final MapEntry(:key, :value) in files.entries) {
    found += value.found;
    hit += value.hit;
    final layer = _layer.firstMatch(key)!.group(1)!;
    final sums = byLayer.putIfAbsent(layer, () => [0, 0]);
    sums[0] += value.found;
    sums[1] += value.hit;
  }
  String pct(int h, int f) =>
      f == 0 ? '100.0' : (100 * h / f).toStringAsFixed(1);
  for (final MapEntry(:key, :value) in byLayer.entries) {
    stdout.writeln('$key: ${pct(value[1], value[0])}% of ${value[0]} lines');
  }
  final total = found == 0 ? 100.0 : 100 * hit / found;
  stdout.writeln('domain + data: ${total.toStringAsFixed(1)}% (minimum $min%)');

  var ok = true;
  if (unloaded.isNotEmpty) {
    stderr
      ..writeln('No test loads these files, so their coverage is unknown:')
      ..writeln(unloaded.map((p) => '  $p').join('\n'));
    ok = false;
  }
  if (total < min) {
    final worst = files.entries.toList()
      ..sort(
        (a, b) => (b.value.found - b.value.hit) - (a.value.found - a.value.hit),
      );
    stderr.writeln('Below $min%. Most uncovered lines:');
    for (final e in worst.take(10)) {
      stderr.writeln(
        '  ${e.key}: ${pct(e.value.hit, e.value.found)}% '
        '(${e.value.found - e.value.hit} lines)',
      );
    }
    ok = false;
  }
  if (!ok) exit(1);
}
