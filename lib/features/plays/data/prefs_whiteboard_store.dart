import 'dart:convert';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/plays/data/firestore_play_repository.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/whiteboard_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The whiteboards in SharedPreferences (localStorage on the web): one JSON
/// map of team ID to its drawing, in the same shape plays are saved in.
class PrefsWhiteboardStore implements WhiteboardStore {
  new(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// The one key it uses, for the cache's allow list in bootstrap.
  static const key = 'playsWhiteboard';

  Map<String, dynamic> _all() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on Object {
      return {};
    }
  }

  @override
  PlayDraft? load(GroupId groupId) {
    final m = _all()[groupId.value];
    if (m is! Map<String, dynamic>) return null;
    final play = playFromFirestore('whiteboard', m);
    return (
      board: play.board,
      variant: play.variant,
      title: play.title,
      note: play.note,
      steps: play.steps,
    );
  }

  @override
  Future<void> save(GroupId groupId, PlayDraft draft) async {
    final all = _all()..[groupId.value] = playToFirestore(draft);
    await _prefs.setString(key, jsonEncode(all));
  }
}
