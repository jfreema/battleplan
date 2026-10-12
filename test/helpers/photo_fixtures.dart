import 'dart:convert';
import 'dart:typed_data';

/// Photo fixtures for the location-stripping tests (Privacy Policy).

/// A real 16x8 JPEG, red on the left and blue on the right, with no
/// metadata (made with `sips`, its APP segments taken out).
final Uint8List plainJpeg = base64.decode(
  '/9j/wAARCAAIABADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL'
  '/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAk'
  'M2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4'
  'eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ'
  '2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL'
  '/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAV'
  'YnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3'
  'eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX'
  '2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9sAQwABAQEBAQECAQECAwICAgMEAwMDAwQFBAQEBAQF'
  'BgUFBQUFBQYGBgYGBgYGBwcHBwcHCAgICAgJCQkJCQkJCQkJ/9sAQwEBAQECAgIEAgIECQYF'
  'BgkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJ/90A'
  'BAAB/9oADAMBAAIRAxEAPwD8x6+f6+gK+f6/tT9iv/zUv/cp/wC7J/oZ+3F/5pf/ALnP/dU/'
  '/9k=',
);

/// The latitude 37° 46' 29.95" as TIFF rationals, little-endian.
final gpsLatitude = Uint8List.fromList([
  for (final v in [37, 1, 46, 1, 2995, 100]) ...[v & 0xFF, v >> 8, 0, 0],
]);

/// An EXIF APP1 segment as a phone writes it: IFD0 with Make, Orientation,
/// the GPS pointer and a title after it, a GPS IFD with coordinates, and an
/// IFD1 (the thumbnail's) after IFD0. Little-endian TIFF, or big-endian if
/// [bigEndian].
Uint8List exifSegment({int orientation = 6, bool bigEndian = false}) {
  final order = bigEndian ? Endian.big : Endian.little;
  final t = ByteData(200);
  var p = 0;
  void u8(int v) => t.setUint8(p++, v);
  void u16(int v) {
    t.setUint16(p, v, order);
    p += 2;
  }

  void u32(int v) {
    t.setUint32(p, v, order);
    p += 4;
  }

  void entry(int tag, int type, int count, int value) {
    u16(tag);
    u16(type);
    u32(count);
    if (type == 3 && count == 1) {
      u16(value);
      u16(0);
    } else {
      u32(value);
    }
  }

  // Header, then IFD0 at 8 with 4 entries: 8 + 2 + 48 + 4 = 62.
  (bigEndian ? [0x4D, 0x4D] : [0x49, 0x49]).forEach(u8);
  u16(42);
  u32(8);
  u16(4);
  entry(0x010F, 2, 8, 120); // Make, out of line
  entry(0x0112, 3, 1, orientation); // Orientation
  entry(0x8825, 4, 1, 62); // GPSInfo
  entry(0x9C9B, 1, 4, 0x41424344); // XPTitle, inline
  u32(160); // IFD1
  // The GPS IFD at 62, 4 entries: 62 + 2 + 48 + 4 = 116.
  u16(4);
  // ASCII values sit in the first bytes of the value field.
  final ascii = bigEndian ? 0x1000000 : 1;
  entry(0x0001, 2, 2, 0x4E * ascii); // GPSLatitudeRef 'N'
  entry(0x0002, 5, 3, 130); // GPSLatitude, out of line
  entry(0x0003, 2, 2, 0x57 * ascii); // GPSLongitudeRef 'W'
  entry(0x0004, 5, 3, 130); // GPSLongitude (same values, fine here)
  u32(0);
  // Make at 120.
  p = 120;
  'Pixel 9\x00'.codeUnits.forEach(u8);
  // Latitude at 130, always little-endian bytes (only searched for).
  p = 130;
  gpsLatitude.forEach(u8);
  // IFD1 at 160: Compression = 6.
  p = 160;
  u16(1);
  entry(0x0103, 3, 1, 6);
  u32(0);
  final tiff = t.buffer.asUint8List(0, p);
  final payload = [...'Exif\x00\x00'.codeUnits, ...tiff];
  final length = payload.length + 2;
  return Uint8List.fromList([
    0xFF,
    0xE1,
    length >> 8,
    length & 0xFF,
    ...payload,
  ]);
}

/// An XMP APP1 segment carrying [body].
Uint8List xmpSegment(String body) {
  final payload = [
    ...'http://ns.adobe.com/xap/1.0/\x00'.codeUnits,
    ...utf8.encode(body),
  ];
  final length = payload.length + 2;
  return Uint8List.fromList([
    0xFF,
    0xE1,
    length >> 8,
    length & 0xFF,
    ...payload,
  ]);
}

/// [plainJpeg] with [segments] inserted after its SOI marker.
Uint8List jpegWith(List<Uint8List> segments) => Uint8List.fromList([
  ...plainJpeg.sublist(0, 2),
  for (final s in segments) ...s,
  ...plainJpeg.sublist(2),
]);

/// The EXIF segment's TIFF block in [jpeg], or null if there is none.
ByteData? exifTiff(Uint8List jpeg) {
  var pos = 2;
  while (pos + 4 <= jpeg.length && jpeg[pos + 1] != 0xDA) {
    final end = pos + 2 + (jpeg[pos + 2] << 8 | jpeg[pos + 3]);
    if (jpeg[pos + 1] == 0xE1 &&
        latin1.decode(jpeg.sublist(pos + 4, pos + 10)) == 'Exif\x00\x00') {
      return ByteData.sublistView(jpeg, pos + 10, end);
    }
    pos = end;
  }
  return null;
}

/// The tags of the IFD at [offset] in [tiff], with each one's first value,
/// and the offset of the next IFD.
(Map<int, int>, int) readIfd(ByteData tiff, int offset) {
  final order = tiff.getUint8(0) == 0x49 ? Endian.little : Endian.big;
  final count = tiff.getUint16(offset, order);
  return (
    {
      for (var i = 0; i < count; i++)
        tiff.getUint16(offset + 2 + 12 * i, order): switch (tiff.getUint16(
          offset + 2 + 12 * i + 2,
          order,
        )) {
          3 => tiff.getUint16(offset + 2 + 12 * i + 8, order),
          _ => tiff.getUint32(offset + 2 + 12 * i + 8, order),
        },
    },
    tiff.getUint32(offset + 2 + 12 * count, order),
  );
}

/// Where [needle] first appears in [hay], or -1.
int indexOfBytes(Uint8List hay, List<int> needle) {
  outer:
  for (var i = 0; i + needle.length <= hay.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (hay[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// The bytes from the start of the image data (SOS) on.
Uint8List imageData(Uint8List jpeg) =>
    jpeg.sublist(indexOfBytes(jpeg, const [0xFF, 0xDA]));
