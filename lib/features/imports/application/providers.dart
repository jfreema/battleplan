import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
ImportRepository importRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');
