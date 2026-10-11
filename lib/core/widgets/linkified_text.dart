import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// A piece of message text: plain, or a link with where it goes.
typedef TextPiece = ({String text, Uri? link});

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

/// Text with tappable links (CHAT-5).
class LinkifiedText extends StatefulWidget {
  const new(
    this.text, {
    required this.onOpen,
    this.style,
    this.linkColor,
    this.phones = true,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final Color? linkColor;
  final bool phones;
  final void Function(Uri link) onOpen;

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

  @override
  Widget build(BuildContext context) {
    _dropRecognizers();
    final pieces = linkify(widget.text, phones: widget.phones);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final p in pieces)
            if (p.link == null)
              TextSpan(text: p.text)
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
