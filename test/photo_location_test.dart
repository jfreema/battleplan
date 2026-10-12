import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battleplan/core/photo_location.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/photo_fixtures.dart';

/// Decodes [jpeg] as the app would and returns its size and RGBA pixels.
Future<(int, int, Uint8List)> _decode(Uint8List jpeg) async {
  final codec = await ui.instantiateImageCodec(jpeg);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData();
  final result = (image.width, image.height, data!.buffer.asUint8List());
  image.dispose();
  codec.dispose();
  return result;
}

class _Picker implements PhotoPicker {
  new(this.photo);

  final Uint8List photo;

  @override
  Future<Uint8List?> pickProfilePhoto() async => photo;

  @override
  Future<List<PickedPhoto>> pickChatPhotos({int limit = 10}) async => [
    (bytes: photo, contentType: 'image/jpeg'),
    (bytes: photo, contentType: 'image/jpeg'),
  ];

  @override
  Future<PickedPhoto?> takeChatPhoto() async =>
      (bytes: photo, contentType: 'image/jpeg');

  @override
  bool get canUseCamera => true;
}

void main() {
  group('photo location is removed before upload (Privacy Policy)', () {
    for (final bigEndian in [false, true]) {
      test('the GPS block goes and the rest stays '
          '(${bigEndian ? 'big' : 'little'}-endian)', () {
        final photo = jpegWith([exifSegment(bigEndian: bigEndian)]);
        // The fixture carries a location to begin with.
        final (before, _) = readIfd(exifTiff(photo)!, 8);
        expect(before, contains(0x8825));
        expect(indexOfBytes(photo, gpsLatitude), isNot(-1));

        final stripped = stripPhotoLocation(photo);
        final tiff = exifTiff(stripped)!;
        final (tags, next) = readIfd(tiff, 8);
        expect(tags.keys, [0x010F, 0x0112, 0x9C9B]);
        expect(tags[0x0112], 6, reason: 'orientation kept');
        expect(tags[0x9C9B], 0x41424344, reason: 'later entries kept');
        // Make's out-of-line value still reads.
        expect(
          latin1.decode(
            Uint8List.sublistView(tiff, tags[0x010F]!, tags[0x010F]! + 7),
          ),
          'Pixel 9',
        );
        // The next-IFD pointer moved with the entries.
        expect(next, 160);
        expect(readIfd(tiff, 160).$1, {0x0103: 6});
        // The coordinates and the GPS IFD are gone from the file.
        expect(indexOfBytes(stripped, gpsLatitude), -1);
        expect(Uint8List.sublistView(tiff, 62, 116), everyElement(0));
        // Nothing re-encoded: same length, same image data.
        expect(stripped.length, photo.length);
        expect(imageData(stripped), imageData(photo));
      });
    }

    testWidgets('it decodes to the same pixels, still rotated', (tester) async {
      final photo = jpegWith([exifSegment()]);
      final (original, stripped) = (await tester.runAsync(
        () async =>
            (await _decode(photo), await _decode(stripPhotoLocation(photo))),
      ))!;
      // Orientation 6 turns the 16x8 photo upright to 8x16.
      expect((stripped.$1, stripped.$2), (8, 16));
      expect((original.$1, original.$2), (8, 16));
      expect(stripped.$3, original.$3);
    });

    test('XMP that names a place is dropped; other XMP is kept', () {
      final located = xmpSegment(
        '<x:xmpmeta><rdf:Description exif:GPSLatitude="37,46.5N"/> '
        '</x:xmpmeta>',
      );
      final plain = xmpSegment(
        '<x:xmpmeta><rdf:Description xmp:Rating="5"/></x:xmpmeta>',
      );
      final stripped = stripPhotoLocation(jpegWith([located, plain]));
      expect(stripped, jpegWith([plain]));
      expect(
        utf8.decode(stripped, allowMalformed: true),
        isNot(contains('GPS')),
      );
    });

    test('an EXIF block it cannot read is dropped whole', () {
      final exif = exifSegment();
      // Point the GPS IFD past the end of the block.
      final broken = Uint8List.fromList(exif);
      ByteData.sublistView(
        broken,
        10,
      ).setUint32(8 + 2 + 12 * 2 + 8, 5000, Endian.little);
      final stripped = stripPhotoLocation(jpegWith([broken]));
      expect(stripped, plainJpeg);
    });

    test('a photo with no location, or not a JPEG, is left alone', () {
      expect(stripPhotoLocation(plainJpeg), plainJpeg);
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
      expect(stripPhotoLocation(png), same(png));
      final pdf = Uint8List.fromList('%PDF-1.7'.codeUnits);
      expect(stripPhotoLocation(pdf), same(pdf));
    });

    test(
      'every photo the picker hands over has its location removed',
      () async {
        final photo = jpegWith([exifSegment()]);
        final picker = LocationStrippingPhotoPicker(_Picker(photo));
        final picked = [
          (await picker.pickProfilePhoto())!,
          for (final p in await picker.pickChatPhotos()) p.bytes,
          (await picker.takeChatPhoto())!.bytes,
        ];
        expect(picked, hasLength(4));
        for (final bytes in picked) {
          expect(indexOfBytes(bytes, gpsLatitude), -1);
          expect(readIfd(exifTiff(bytes)!, 8).$1[0x0112], 6);
        }
      },
    );
  });
}
