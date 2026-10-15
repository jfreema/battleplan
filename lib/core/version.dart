/// Compares dotted version strings ("1.2.10" > "1.2.9"). Missing parts count
/// as zero, and anything after `+` or `-` is ignored.
int compareVersions(String a, String b) {
  List<int> parse(String v) => v
      .split(RegExp('[+-]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parse(a);
  final pb = parse(b);
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// Which build this is (ARCH §9, versioning): the semantic version from
/// pubspec, the build number, and the commit it was built from. Release
/// and CI builds number themselves by the commits on `main`
/// (`tools/build_hosting.sh`), so every build of a commit has the same
/// number and each push a higher one. A local `flutter run` has pubspec's
/// number and no commit.
class AppBuild {
  const new({
    required this.version,
    required this.number,
    required this.commit,
  });

  /// "0.1.0": what the forced-update check compares.
  final String version;

  /// "312", or empty when the platform gave none.
  final String number;

  /// The short commit ID, "806de75", or empty for a local build.
  final String commit;

  /// "0.1.0+312.806de75" (semantic versioning's build metadata), for error
  /// reports and device records.
  String get full => [
    version,
    if (number.isNotEmpty || commit.isNotEmpty)
      [if (number.isNotEmpty) number, if (commit.isNotEmpty) commit].join('.'),
  ].join('+');
}
