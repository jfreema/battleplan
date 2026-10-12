import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Light taps of feedback on iOS and Android; none on the web (SPEC §4.2
/// parity table: Haptics). Each call is fire-and-forget.
abstract final class Haptics {
  /// Whether this platform gets haptics. Tests can turn it on.
  @visibleForTesting
  static bool enabled = !kIsWeb;

  /// A choice made: an RSVP answer, a reply by swiping.
  static void selection() => _run(HapticFeedback.selectionClick);

  /// Something sent or added: a message, a reaction.
  static void light() => _run(HapticFeedback.lightImpact);

  /// A long-press that opens a menu.
  static void medium() => _run(HapticFeedback.mediumImpact);

  static void _run(Future<void> Function() feedback) {
    if (enabled) unawaited(feedback());
  }
}
