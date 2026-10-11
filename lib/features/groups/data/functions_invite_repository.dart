import 'package:battleplan/core/constants.g.dart';
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
  Future<InvitePreview> preview(String code) async {
    final d = await _raw('getInvitePreview', {'code': code});
    return InvitePreview(
      groupId: d['groupId'] as String,
      name: d['name'] as String,
      sport: Sport.tryParse(d['sport'] as String?) ?? Sport.other,
      teamType: TeamType.tryParse(d['teamType'] as String?) ?? TeamType.adult,
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
      color: _color(d['color'] as String?),
      invitedBy: d['invitedBy'] as String?,
    );
  }

  @override
  Future<JoinResult> redeem(String code) async {
    final d = await _raw('redeemInvite', {'code': code});
    return JoinResult(
      groupId: d['groupId'] as String,
      teamType: TeamType.tryParse(d['teamType'] as String?) ?? TeamType.adult,
      alreadyMember: d['alreadyMember'] as bool? ?? false,
    );
  }

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

  Future<TeamInvite> _call(String name, Map<String, Object?> data) async =>
      _invite(await _raw(name, data));

  Future<Map<String, dynamic>> _raw(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw switch ((e.code, e.message)) {
        ('not-found', final reason?) => InviteUnusable(reason),
        ('failed-precondition', 'too-many-teams') => TooManyTeams(e.message),
        ('resource-exhausted', _) => RateLimited(e.message),
        ('permission-denied', _) => PermissionDenied(e.message),
        ('invalid-argument', _) => const InviteUnusable('unknown'),
        ('unavailable' || 'deadline-exceeded', _) => Offline(e.message),
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

int? _color(String? hex) {
  if (hex == null || hex.length != 7) return null;
  final rgb = int.tryParse(hex.substring(1), radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}
