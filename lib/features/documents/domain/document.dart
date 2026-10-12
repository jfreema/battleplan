import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';

/// The longest name, description, and link the rules accept (ARCH §6.2
/// `groupDocuments`).
// TODO(M7): move these three to shared/constants.json with the rules.
const int documentNameMax = 100;
const int documentDescriptionMax = 500;
const int documentUrlMax = 2000;

/// The largest file a team can upload (STORE-1), in bytes.
const int documentMaxBytes = Limits.maxUploadMb * 1024 * 1024;

/// What a document is, for its icon and how it opens (DOC-1, DOC-4).
enum DocumentType {
  pdf,
  image,
  word,
  excel,
  powerpoint,
  text,
  csv,
  link,
  other,
}

/// A file or link shared with the team (ARCH §6.2 `groupDocuments`).
@freezed
abstract class Document with _$Document {
  const factory({
    required DocumentId id,
    required GroupId groupId,
    required DocumentKind kind,
    required String name,

    /// Who added it, and their name then, kept after they leave (DOC-1).
    required String uploadedBy,
    required String uploaderName,
    @Default('') String description,

    /// Pinned items list first (DOC-1); only admins change it (DOC-5).
    @Default(false) bool pinned,

    /// Files: the Storage path, its type, and its size in bytes.
    String? path,
    String? contentType,
    int? size,

    /// Links: the web address (DOC-3).
    String? url,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Document;

  const new _();

  bool get isLink => kind == DocumentKind.link;

  DocumentType get type =>
      isLink ? DocumentType.link : documentTypeOf(contentType);

  /// PDFs and images open in the app's viewer (DOC-4).
  bool get opensInApp => type == DocumentType.pdf || type == DocumentType.image;

  /// The name to save or share the file as: the stored file's own name,
  /// which keeps its extension even when the document was renamed.
  String get fileName {
    final p = path;
    if (p == null) return name;
    final i = p.lastIndexOf('/');
    return i < 0 ? p : p.substring(i + 1);
  }
}

/// The content type of each file extension people can upload (DOC-2): the
/// same list as storage.rules' `isDocument`.
const Map<String, String> documentContentTypes = {
  'pdf': 'application/pdf',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'txt': 'text/plain',
  'csv': 'text/csv',
};

/// The content type for [fileName] from its extension, or null when it
/// isn't a type people can upload.
String? contentTypeForFile(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;
  return documentContentTypes[fileName.substring(dot + 1).toLowerCase()];
}

/// [contentType] as a [DocumentType], for the icon and the viewer.
DocumentType documentTypeOf(String? contentType) {
  final t = contentType ?? '';
  if (t == 'application/pdf') return DocumentType.pdf;
  if (t.startsWith('image/')) return DocumentType.image;
  if (t == 'text/csv') return DocumentType.csv;
  if (t == 'text/plain') return DocumentType.text;
  if (t.contains('word')) return DocumentType.word;
  if (t.contains('excel') || t.contains('spreadsheet')) {
    return DocumentType.excel;
  }
  if (t.contains('powerpoint') || t.contains('presentation')) {
    return DocumentType.powerpoint;
  }
  return DocumentType.other;
}

/// [text] as a link people can add (DOC-3): http or https with a host, up
/// to 2,000 characters. A bare "example.com" gets https in front. Null when
/// it isn't one.
Uri? parseDocumentUrl(String text) {
  var t = text.trim();
  if (t.isEmpty || t.contains(RegExp(r'\s'))) return null;
  if (!t.contains('://')) t = 'https://$t';
  if (t.length > documentUrlMax) return null;
  final uri = Uri.tryParse(t);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return null;
  }
  if (uri.host.isEmpty ||
      (!uri.host.contains('.') && uri.host != 'localhost')) {
    return null;
  }
  return uri;
}

/// Whether [name] works as a document name: something besides spaces, up
/// to 100 characters as the rules count them (code points).
bool isValidDocumentName(String name) {
  final t = name.trim();
  return t.isNotEmpty && t.runes.length <= documentNameMax;
}

/// Whether [description] fits (500 characters; empty is fine).
bool isValidDocumentDescription(String description) =>
    description.trim().runes.length <= documentDescriptionMax;

/// How the Documents tab orders its rows (DOC-1).
enum DocumentSort { recent, name }

/// DOC-1's order: pinned first, then [sort] (newest first, or by name),
/// keeping only names containing [filter] (case-insensitive).
List<Document> arrangeDocuments(
  Iterable<Document> docs, {
  required DocumentSort sort,
  String filter = '',
}) {
  final f = filter.trim().toLowerCase();
  final list = [
    for (final d in docs)
      if (f.isEmpty || d.name.toLowerCase().contains(f)) d,
  ];
  int byRecent(Document a, Document b) {
    final x = a.createdAt ?? DateTime.now();
    final y = b.createdAt ?? DateTime.now();
    final c = y.compareTo(x);
    return c != 0 ? c : a.id.value.compareTo(b.id.value);
  }

  int byName(Document a, Document b) {
    final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return c != 0 ? c : byRecent(a, b);
  }

  return list..sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return sort == DocumentSort.name ? byName(a, b) : byRecent(a, b);
  });
}
