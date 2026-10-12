import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/domain/admin_repository.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';

/// Saves edits to a team's profile, settings, logo, and chat look (TEAM-5,
/// CHAT-18). Its admins write the team directly. The rules let only them,
/// so a super admin who isn't one goes through `adminUpdateGroup` instead,
/// which checks the claim, applies the same limits, and audits the change
/// (ADMIN-3, ADMIN-8). Logo and background files upload the same way for
/// both; only where the path is saved differs.
class TeamEditor {
  const new(this._groups, this._admin, {required this.asSuperAdmin});

  final GroupRepository _groups;
  final AdminRepository _admin;

  /// True for a super admin who isn't an admin of this team.
  final bool asSuperAdmin;

  /// Edits the profile and settings (TEAM-5).
  Future<void> update(
    GroupId id, {
    String? name,
    Sport? sport,
    String? color,
    String? description,
    String? timeZone,
    GroupSettings? settings,
  }) => asSuperAdmin
      ? _admin.updateGroup(
          id,
          name: name,
          sport: sport,
          color: color,
          description: description,
          timeZone: timeZone,
          settings: settings,
        )
      : _groups.updateGroup(
          id,
          name: name,
          sport: sport,
          color: color,
          description: description,
          timeZone: timeZone,
          settings: settings,
        );

  /// Uploads and sets a new logo (TEAM-5).
  Future<void> uploadLogo(GroupId id, Uint8List jpegBytes) async {
    if (!asSuperAdmin) {
      await _groups.uploadLogo(id, jpegBytes);
      return;
    }
    final path = await _groups.uploadLogoFile(id, jpegBytes);
    await _admin.updateGroup(id, photoPath: path);
  }

  /// Saves the chat look (CHAT-18).
  Future<void> updateChatTheme(GroupId id, ChatTheme theme) => asSuperAdmin
      ? _admin.updateGroup(id, chatTheme: theme)
      : _groups.updateChatTheme(id, theme);

  /// Uploads a chat background photo and returns its path, for
  /// [updateChatTheme] to save (CHAT-18).
  Future<String> uploadChatBackground(GroupId id, Uint8List jpegBytes) =>
      _groups.uploadChatBackground(id, jpegBytes);
}
