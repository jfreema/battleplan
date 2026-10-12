import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/media.dart';

/// A team's stored files through the storage callables (STORE-5, ARCH
/// §6.11). Team admins only; Functions read the bucket and fix what pointed
/// at a deleted file.
abstract interface class MediaRepository {
  /// Every file under `groups/{g}/`, largest first, with the team's usage
  /// (`listTeamMedia`).
  Future<TeamMedia> list(GroupId groupId);

  /// Deletes one file (`deleteTeamMedia`): a chat photo leaves its message,
  /// and the logo or background resets. Storage use drops within seconds.
  Future<void> delete(GroupId groupId, String path);
}
