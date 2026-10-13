import 'package:battleplan/core/widgets/linkified_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('highlights stretches of plain text and keeps links whole '
      '(CHAT-14)', (tester) async {
    const text = 'Hi @Sam Rivera, see https://a.co @Alex';
    const bold = TextStyle(fontWeight: FontWeight.w700);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LinkifiedText(
          text,
          onOpen: (_) {},
          highlights: const [
            (start: 3, end: 14, style: bold),
            (start: 33, end: 38, style: bold),
          ],
        ),
      ),
    );
    final spans = <TextSpan>[];
    tester.widget<Text>(find.byType(Text)).textSpan!.visitChildren((s) {
      if (s is TextSpan && s.text != null) spans.add(s);
      return true;
    });
    expect(spans.map((s) => s.text).join(), text);
    expect(
      [
        for (final s in spans)
          if (s.style?.fontWeight == FontWeight.w700) s.text,
      ],
      ['@Sam Rivera', '@Alex'],
    );
    expect(spans.where((s) => s.recognizer != null).map((s) => s.text), [
      'https://a.co',
    ]);
  });
}
