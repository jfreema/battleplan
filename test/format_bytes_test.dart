import 'package:battleplan/features/groups/presentation/storage_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('storage sizes read naturally', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(512 * 1024), '512 KB');
    expect(formatBytes(1288490189), '1.2 GB');
    expect(formatBytes(5 * 1024 * 1024 * 1024), '5.0 GB');
  });
}
