import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
PushRepository pushRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');
