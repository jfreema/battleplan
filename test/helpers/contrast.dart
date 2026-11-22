// The text contrast check for Boot Camp Mix (#85, #86): Flutter's own, but
// for outlined lettering (`OutlinedText`: page titles, the event's title,
// its counts). Those are white, or an answer's color, inside a thick ink
// outline on a hard shadow, and they read by the outline: on a light page
// (Light, Sky Blue) the check would compare the white fill with the page
// and miss the outline between them. The outline's contrast with every
// page, panel and camouflage is checked instead, in every scheme, by
// test/camp_lettering_test.dart.
import 'package:battleplan/core/widgets/camp_lettering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// [MinimumTextContrastGuideline], skipping outlined lettering.
class OutlineAwareContrastGuideline extends MinimumTextContrastGuideline {
  const new();

  @override
  bool shouldSkipNode(SemanticsData data) =>
      data.identifier == OutlinedText.semanticsIdentifier ||
      super.shouldSkipNode(data);
}

/// The app's text contrast check: 4.5:1 for text, 3:1 for large text, with
/// outlined lettering checked by its outline.
const AccessibilityGuideline textContrast = OutlineAwareContrastGuideline();
