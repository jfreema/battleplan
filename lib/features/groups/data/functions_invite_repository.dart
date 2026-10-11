import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/invite_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Invites through the `getTeamInvite` and `resetGroupInvite` callables.
class FunctionsInviteRepository implements InviteRepository {
  new(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<TeamInvite> teamInvite(GroupId groupId) =>
      _call('getTeamInvite', {'groupId': groupId.value});

  @override
  Future<TeamInvite> resetTeamInvite(
    GroupId groupId, {
    InviteExpiry expiry = InviteExpiry.never,
    int? maxUses,
  }) => _call('resetGroupInvite', {
    'groupId': groupId.value,
    'expiresInDays': expiry.days,
    'maxUses': maxUses,
  });

  Future<TeamInvite> _call(String name, Map<String, Object?> data) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return _invite(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }
}

TeamInvite _invite(Map<String, dynamic> d) => TeamInvite(
  code: d['code'] as String,
  display: d['display'] as String,
  url: Uri.parse(d['url'] as String),
  useCount: (d['useCount'] as num?)?.toInt() ?? 0,
  expiresAt: d['expiresAt'] == null
      ? null
      : DateTime.parse(d['expiresAt'] as String),
  maxUses: (d['maxUses'] as num?)?.toInt(),
);
