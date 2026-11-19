import 'dart:convert';

import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/invite_screen.dart';
import 'package:battleplan/features/groups/presentation/join_screen.dart';

/// Keeps the app's route extras through go_router's refreshes and the web's
/// back and forward (ARCH §5.4).
///
/// A refresh re-runs the redirects whenever sign-in, my teams, or my
/// profile change (`router`'s `refreshListenable`), and go_router keeps a
/// page's extra across it only through a codec. Without one it dropped
/// them: a page opened from Teams lost "‹ Teams" the moment the email was
/// verified, and Invite lost "Hornets is ready!" as the new team arrived
/// (#33). Each extra the app passes is here; any other is dropped, as
/// before.
class RouteExtraCodec extends Codec<Object?, Object?> {
  const new();

  @override
  Converter<Object?, Object?> get encoder => const _Encode();

  @override
  Converter<Object?, Object?> get decoder => const _Decode();
}

class _Encode extends Converter<Object?, Object?> {
  const new();

  @override
  Object? convert(Object? input) => switch (input) {
    // Before BackLabel, which it extends.
    FromCodeBox(:final label) => {'type': 'fromCodeBox', 'label': label},
    BackLabel(:final label) => {'type': 'backLabel', 'label': label},
    InviteAfterCreate() => const {'type': 'inviteAfterCreate'},
    _ => null,
  };
}

class _Decode extends Converter<Object?, Object?> {
  const new();

  @override
  Object? convert(Object? input) => switch (input) {
    {'type': 'fromCodeBox', 'label': final String? label} => FromCodeBox(label),
    {'type': 'backLabel', 'label': final String? label} => BackLabel(label),
    {'type': 'inviteAfterCreate'} => const InviteAfterCreate(),
    _ => null,
  };
}
