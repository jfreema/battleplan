import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/play_repository.dart';
import 'package:battleplan/features/plays/domain/whiteboard_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
PlayRepository playRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The team's plays, most recently changed first (BOARD-4).
@riverpod
Stream<List<Play>> teamPlays(Ref ref, GroupId groupId) =>
    ref.watch(playRepositoryProvider).watchPlays(groupId);

/// One play, live; null once it's deleted.
@riverpod
Stream<Play?> play(Ref ref, PlayId id) =>
    ref.watch(playRepositoryProvider).watchPlay(id);

/// The whiteboard on this device (BOARD-2): kept until it's cleared.
@Riverpod(keepAlive: true)
WhiteboardStore whiteboardStore(Ref ref) => MemoryWhiteboardStore();
