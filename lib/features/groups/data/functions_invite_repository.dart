import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/invite_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Invites through the invite callables (`getTeamInvite`, `redeemInvite`,
/// `sendEmailInvites`, and the rest).
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
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
      color: _color(d['color'] as String?),
      logoUrl: d['logoUrl'] as String?,
      invitedBy: d['invitedBy'] as String?,
    );
  }

  @override
  Future<JoinResult> redeem(String code) async {
    final d = await _raw('redeemInvite', {'code': code});
    return JoinResult(
      groupId: d['groupId'] as String,
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

  @override
  Future<TeamInvite> updateTeamInvite(
    GroupId groupId, {
    InviteExpiry expiry = InviteExpiry.never,
    int? maxUses,
  }) => _call('updateGroupInvite', {
    'groupId': groupId.value,
    'expiresInDays': expiry.days,
    'maxUses': maxUses,
  });

  @override
  Future<void> revokeTeamInvite(GroupId groupId) =>
      _raw('revokeGroupInvite', {'groupId': groupId.value});

  @override
  Future<int> sendEmailInvites(
    GroupId groupId,
    List<String> emails, {
    String? note,
  }) async {
    final d = await _raw('sendEmailInvites', {
      'groupId': groupId.value,
      'emails': emails,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return (d['invited'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<EmailInvite>> emailInvites(GroupId groupId) async {
    final d = await _raw('listEmailInvites', {'groupId': groupId.value});
    return [
      for (final x in (d['invites'] as List).cast<Map<Object?, Object?>>())
        EmailInvite(
          code: x['code']! as String,
          email: x['email']! as String,
          status: EmailInviteStatus.values.byName(x['status']! as String),
          createdAt: x['createdAt'] == null
              ? null
              : DateTime.parse(x['createdAt']! as String),
        ),
    ];
  }

  @override
  Future<void> resendEmailInvite(String code) =>
      _raw('resendEmailInvite', {'code': code});

  @override
  Future<void> revokeInvite(String code) =>
      _raw('revokeInvite', {'code': code});

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
        // An admin turned the team's link off (§3).
        ('failed-precondition', 'link-off') => const InviteUnusable('link-off'),
        ('failed-precondition', 'too-many-teams') => TooManyTeams(e.message),
        ('failed-precondition', 'email-not-verified') => EmailNotVerified(
          e.message,
        ),
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
