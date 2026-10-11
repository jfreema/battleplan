import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';

/// A team (ARCH §6.2 `groups`). Only the fields M0 screens need so far.
@freezed
abstract class Group with _$Group {
  const factory({
    required GroupId id,
    required String name,
    required Sport sport,
    required TeamType teamType,
    required int memberCount,
    String? description,

    /// ARGB team color (one of `teamColorValues`).
    int? color,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    DateTime? archivedAt,
    DateTime? suspendedAt,
  }) = _Group;

  const new _();

  bool get isArchived => archivedAt != null;
}
