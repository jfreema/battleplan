import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

/// Who may do what with documents, as the rules decide (DOC-2, DOC-5,
/// TEAM-5, TEAM-9). Archived teams are read-only for everyone.

/// Adding files or links (+): admins, or members when the team lets them
/// (`membersCanUploadDocs`, on by default).
bool canAddDocuments(Group group, Membership? me) =>
    me != null &&
    !group.isArchived &&
    (me.isAdmin || group.settings.membersCanUploadDocs);

/// Renaming, editing the description, and deleting: the uploader or an
/// admin. Super admins may delete too.
bool canManageDocument(Document doc, Group group, Membership? me) =>
    me != null &&
    !group.isArchived &&
    (me.isAdmin || doc.uploadedBy == me.uid.value);

/// Deleting: anyone who can manage it, or a super admin (ARCH §6.3).
bool canDeleteDocument(
  Document doc,
  Group group,
  Membership? me, {
  bool superAdmin = false,
}) => canManageDocument(doc, group, me) || (superAdmin && !group.isArchived);

/// Pinning and unpinning: admins only (DOC-5).
bool canPinDocument(Group group, Membership? me) =>
    me != null && !group.isArchived && me.isAdmin;

/// Reporting (SAFE-1): anything someone else added.
bool canReportDocument(Document doc, Membership? me) =>
    me != null && doc.uploadedBy != me.uid.value;
