import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

/// Who may do what with documents, as the rules decide (DOC-2, DOC-5,
/// TEAM-5, TEAM-9). Archived teams are read-only for everyone.

/// Adding files or links (+): admins, or members when the team lets them
/// (`membersCanUploadDocs`, on by default). Super admins add them on teams
/// they've joined, whatever the setting (§3).
bool canAddDocuments(Group group, Membership? me, {bool superAdmin = false}) =>
    me != null &&
    !group.isArchived &&
    (superAdmin || me.isAdmin || group.settings.membersCanUploadDocs);

/// Renaming, editing the description, and deleting: the uploader, an
/// admin, or a super admin on any team (§3).
bool canManageDocument(
  Document doc,
  Group group,
  Membership? me, {
  bool superAdmin = false,
}) =>
    !group.isArchived &&
    (superAdmin ||
        (me != null && (me.isAdmin || doc.uploadedBy == me.uid.value)));

/// Deleting: anyone who can manage it, or a super admin (ARCH §6.3).
bool canDeleteDocument(
  Document doc,
  Group group,
  Membership? me, {
  bool superAdmin = false,
}) => canManageDocument(doc, group, me, superAdmin: superAdmin);

/// Pinning and unpinning: admins (DOC-5), and super admins on any team (§3).
bool canPinDocument(Group group, Membership? me, {bool superAdmin = false}) =>
    !group.isArchived && (superAdmin || (me?.isAdmin ?? false));

/// Reporting (SAFE-1): anything someone else added.
bool canReportDocument(Document doc, Membership? me) =>
    me != null && doc.uploadedBy != me.uid.value;

/// [fileName] safe as one Storage path segment: no slashes or control
/// characters, at most 100 characters, keeping the extension.
String storageFileName(String fileName) {
  var name = fileName.replaceAll(RegExp(r'[/\\\x00-\x1f#\[\]*?]'), '_').trim();
  if (name.isEmpty || name == '.' || name == '..') name = 'file';
  if (name.length > 100) {
    final dot = name.lastIndexOf('.');
    final ext = dot > 0 && name.length - dot <= 10 ? name.substring(dot) : '';
    name = name.substring(0, 100 - ext.length) + ext;
  }
  return name;
}
