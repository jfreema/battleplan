import 'package:battleplan/core/services/link_opener.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service_providers.g.dart';

/// Platform services screens use directly. Declared in core/ so presentation
/// code can reach them; implementations are wired in app/providers.dart.

/// Picks profile photos.
@Riverpod(keepAlive: true)
PhotoPicker photoPicker(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Opens web and mailto links.
@Riverpod(keepAlive: true)
LinkOpener linkOpener(Ref ref) => const NoopLinkOpener();
