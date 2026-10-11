import 'package:battleplan/core/widgets/linkified_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String?> links(String text, {bool phones = true}) => [
    for (final p in linkify(text, phones: phones))
      if (p.link != null) p.link.toString(),
  ];

  test('finds web addresses without trailing punctuation', () {
    expect(links('Field map: https://example.com/map. See you!'), [
      'https://example.com/map',
    ]);
    expect(links('www.example.org works too'), ['https://www.example.org']);
  });

  test('finds emails and phone numbers', () {
    expect(links('Email coach@example.com or call (555) 123-4567'), [
      'mailto:coach@example.com',
      'tel:5551234567',
    ]);
  });

  test('leaves phone numbers alone when asked (web)', () {
    expect(links('Call 555-123-4567', phones: false), isEmpty);
  });

  test('keeps the text intact', () {
    const text = 'Go to https://a.co now, ok?';
    expect(linkify(text).map((p) => p.text).join(), text);
  });

  test('does not treat scores or times as phone numbers', () {
    expect(links('We won 5-3 at 6:30'), isEmpty);
  });
}
