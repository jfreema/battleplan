import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
PlayerRepository playerRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// A youth team's players, by jersey number then name (TEAM-3).
@riverpod
Stream<List<Player>> players(Ref ref, GroupId groupId) =>
    ref.watch(playerRepositoryProvider).watchPlayers(groupId).map((list) {
      int number(Player p) => int.tryParse(p.jerseyNumber ?? '') ?? 1 << 20;
      return [...list]..sort((a, b) {
        final byNumber = number(a).compareTo(number(b));
        return byNumber != 0
            ? byNumber
            : a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
      });
    });

/// A youth team's guardian links.
@riverpod
Stream<List<GuardianLink>> guardianLinks(Ref ref, GroupId groupId) =>
    ref.watch(playerRepositoryProvider).watchGuardianLinks(groupId);
