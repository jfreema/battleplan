import 'dart:convert';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/chat_queue_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The send queue in SharedPreferences (localStorage on web), one JSON map
/// of team ID to its queued messages (CHAT-4).
class PrefsChatQueueStore implements ChatQueueStore {
  new(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// The one key it uses, for the cache's allow list in bootstrap.
  static const key = 'chatSendQueue';

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
  List<SavedText> load(GroupId groupId) {
    final list = _all()[groupId.value];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map && e['id'] is String && e['text'] is String)
          SavedText(
            id: e['id'] as String,
            text: e['text'] as String,
            replyToId: e['replyToId'] as String?,
            mentions: [
              for (final uid in (e['mentions'] as List?) ?? const [])
                if (uid is String) uid,
            ],
            mentionsEveryone: e['mentionsEveryone'] == true,
            announcement: e['announcement'] == true,
          ),
    ];
  }

  @override
  Future<void> save(GroupId groupId, List<SavedText> items) {
    final all = _all();
    if (items.isEmpty) {
      all.remove(groupId.value);
    } else {
      all[groupId.value] = [
        for (final i in items)
          {
            'id': i.id,
            'text': i.text,
            'replyToId': i.replyToId,
            if (i.mentions.isNotEmpty) 'mentions': i.mentions,
            if (i.mentionsEveryone) 'mentionsEveryone': true,
            if (i.announcement) 'announcement': true,
          },
      ];
    }
    return all.isEmpty
        ? _prefs.remove(key)
        : _prefs.setString(key, jsonEncode(all));
  }
}
