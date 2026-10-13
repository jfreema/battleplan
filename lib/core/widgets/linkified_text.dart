import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// A piece of message text: plain, or a link with where it goes.
typedef TextPiece = ({String text, Uri? link});

/// A stretch of text from `start` to `end`, shown in `style`: an @mention
/// (CHAT-14).
typedef TextHighlight = ({int start, int end, TextStyle style});

final _linkPattern = RegExp(
  // Web addresses, email addresses, then phone numbers (CHAT-5).
  '((?:https?://|www\\.)[^\\s<>]+[^\\s<>.,;:!?)\\]}"\'])'
  r'|([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})'
  r'|(\+?\d[\d\s().-]{7,}\d)',
);

/// Splits [text] into plain pieces and links. Phone numbers become links
/// only when [phones] is true (phones can call; web can't).
List<TextPiece> linkify(String text, {bool phones = true}) {
  final pieces = <TextPiece>[];
  var start = 0;
  for (final m in _linkPattern.allMatches(text)) {
    Uri? link;
    if (m.group(1) case final url?) {
      link = Uri.tryParse(url.startsWith('www.') ? 'https://$url' : url);
    } else if (m.group(2) case final email?) {
      link = Uri(scheme: 'mailto', path: email);
    } else if (phones && m.group(3) != null) {
      final digits = m.group(3)!.replaceAll(RegExp(r'[^\d+]'), '');
      if (digits.replaceAll('+', '').length >= 7) {
        link = Uri(scheme: 'tel', path: digits);
      }
    }
    if (link == null) continue;
    if (m.start > start) {
      pieces.add((text: text.substring(start, m.start), link: null));
    }
    pieces.add((text: m.group(0)!, link: link));
    start = m.end;
  }
  if (start < text.length) {
    pieces.add((text: text.substring(start), link: null));
  }
  return pieces;
}

/// Text with tappable links (CHAT-5), and [highlights] such as @mentions
/// (CHAT-14) styled apart.
class LinkifiedText extends StatefulWidget {
  const new(
    this.text, {
    required this.onOpen,
    this.style,
    this.linkColor,
    this.phones = true,
    this.highlights = const [],
    super.key,
  });

  final String text;
  final TextStyle? style;
  final Color? linkColor;
  final bool phones;
  final void Function(Uri link) onOpen;

  /// Stretches of the text to style apart, in order and not overlapping.
  /// Links inside them stay plain links.
  final List<TextHighlight> highlights;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _dropRecognizers();
    super.dispose();
  }

  void _dropRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  /// [text], which starts at [from] in the whole text, split where
  /// [LinkifiedText.highlights] begin and end.
  List<TextSpan> _plain(String text, int from) {
    final spans = <TextSpan>[];
    var at = from;
    final end = from + text.length;
    for (final h in widget.highlights) {
      if (h.end <= at || h.start >= end) continue;
      final start = h.start < at ? at : h.start;
      final stop = h.end > end ? end : h.end;
      if (start > at) {
        spans.add(TextSpan(text: text.substring(at - from, start - from)));
      }
      spans.add(
        TextSpan(
          text: text.substring(start - from, stop - from),
          style: h.style,
        ),
      );
      at = stop;
    }
    if (at < end) spans.add(TextSpan(text: text.substring(at - from)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _dropRecognizers();
    final pieces = linkify(widget.text, phones: widget.phones);
    final starts = <int>[];
    var offset = 0;
    for (final p in pieces) {
      starts.add(offset);
      offset += p.text.length;
    }
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final (i, p) in pieces.indexed)
            if (p.link == null)
              ..._plain(p.text, starts[i])
            else
              TextSpan(
                text: p.text,
                style: TextStyle(
                  color: widget.linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: widget.linkColor,
                ),
                recognizer:
                    (TapGestureRecognizer()
                        ..onTap = () => widget.onOpen(p.link!))
                      .._keep(_recognizers),
              ),
        ],
      ),
    );
  }
}

extension on TapGestureRecognizer {
  void _keep(List<TapGestureRecognizer> list) => list.add(this);
}
