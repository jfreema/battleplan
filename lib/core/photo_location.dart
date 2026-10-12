import 'dart:convert';
import 'dart:typed_data';

/// Removes location from a JPEG photo before it's uploaded (Privacy Policy:
/// "The app removes location data from photos before uploading them").
///
/// Phones write where a photo was taken into its EXIF GPS block, and
/// `image_picker` copies that block into the resized file. This removes the
/// GPS block and any XMP packet that names a place, and keeps everything
/// else, the orientation above all, without re-encoding: the image data is
/// copied byte for byte.
///
/// Anything that isn't a JPEG comes back as is. If the EXIF block can't be
/// read safely, all of it is dropped rather than risk keeping the location.
Uint8List stripPhotoLocation(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return bytes;
  final out = BytesBuilder(copy: false)..add(bytes.sublist(0, 2));
  var pos = 2;
  while (pos + 4 <= bytes.length) {
    if (bytes[pos] != 0xFF) break;
    final marker = bytes[pos + 1];
    // Fill bytes before a marker.
    if (marker == 0xFF) {
      out.addByte(0xFF);
      pos++;
      continue;
    }
    // The image data starts (SOS), or it ends: copy the rest as is.
    if (marker == 0xDA || marker == 0xD9) break;
    // Markers with no length.
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      out.add(bytes.sublist(pos, pos + 2));
      pos += 2;
      continue;
    }
    final end = pos + 2 + (bytes[pos + 2] << 8 | bytes[pos + 3]);
    if (end > bytes.length) break;
    final segment = Uint8List.fromList(bytes.sublist(pos, end));
    if (marker == 0xE1) {
      final kept = _app1WithoutLocation(segment);
      if (kept != null) out.add(kept);
    } else {
      out.add(segment);
    }
    pos = end;
  }
  out.add(bytes.sublist(pos));
  return out.takeBytes();
}

const _exifId = 'Exif\x00\x00';
const _xmpIds = [
  'http://ns.adobe.com/xap/1.0/\x00',
  'http://ns.adobe.com/xmp/extension/\x00',
];

/// XMP that names a place: GPS coordinates (`exif:GPSLatitude`), or a
/// location someone filled in (`Iptc4xmpCore:Location`, `photoshop:City`).
final _xmpLocation = RegExp('GPS|Location|City');

/// An APP1 [segment] with its location removed, or null to drop it.
Uint8List? _app1WithoutLocation(Uint8List segment) {
  final payload = segment.sublist(4);
  bool startsWith(String id) =>
      payload.length >= id.length &&
      latin1.decode(payload.sublist(0, id.length)) == id;
  if (startsWith(_exifId)) {
    // The TIFF block follows the 6-byte id; its offsets are relative to it.
    final tiff = ByteData.sublistView(segment, 4 + _exifId.length);
    return _removeGps(tiff) ? segment : null;
  }
  for (final id in _xmpIds) {
    if (startsWith(id)) {
      final xmp = latin1.decode(payload.sublist(id.length));
      return _xmpLocation.hasMatch(xmp) ? null : segment;
    }
  }
  return segment;
}

/// The GPS IFD pointer in IFD0 (EXIF 2.3 §4.6.3).
const _gpsInfoTag = 0x8825;

/// Bytes per value of each TIFF field type.
const _typeSizes = {
  1: 1, 2: 1, 3: 2, 4: 4, 5: 8, 6: 1, 7: 1, //
  8: 2, 9: 4, 10: 8, 11: 4, 12: 8, 13: 4,
};

/// Removes the GPS IFD from a TIFF block in place: its entries and the
/// values they point to are zeroed, and its entry in IFD0 is taken out.
/// False if the block can't be read, so the caller drops it whole.
bool _removeGps(ByteData tiff) {
  try {
    final order = switch ((tiff.getUint8(0), tiff.getUint8(1))) {
      (0x49, 0x49) => Endian.little,
      (0x4D, 0x4D) => Endian.big,
      _ => throw const FormatException('byte order'),
    };
    int u16(int at) => tiff.getUint16(at, order);
    int u32(int at) => tiff.getUint32(at, order);
    void zero(int from, int to) {
      if (from < 0 || to > tiff.lengthInBytes || from > to) {
        throw const FormatException('out of range');
      }
      for (var i = from; i < to; i++) {
        tiff.setUint8(i, 0);
      }
    }

    if (u16(2) != 42) return false;
    final ifd0 = u32(4);
    final count = u16(ifd0);
    final entries = ifd0 + 2;
    // The entries and the pointer to the next IFD.
    final ifdEnd = entries + 12 * count + 4;
    if (ifdEnd > tiff.lengthInBytes) return false;
    final index = [for (var i = 0; i < count; i++) u16(entries + 12 * i)]
        .indexOf(_gpsInfoTag);
    if (index < 0) return true;

    // Zero the GPS IFD and every value it points to.
    final gps = u32(entries + 12 * index + 8);
    final gpsCount = u16(gps);
    for (var i = 0; i < gpsCount; i++) {
      final entry = gps + 2 + 12 * i;
      final size = (_typeSizes[u16(entry + 2)] ?? 1) * u32(entry + 4);
      if (size > 4) {
        final at = u32(entry + 8);
        zero(at, at + size);
      }
    }
    zero(gps, gps + 2 + 12 * gpsCount + 4);

    // Take its entry out of IFD0: the later entries and the next-IFD
    // pointer move up, and the freed 12 bytes are zeroed.
    final at = entries + 12 * index;
    final moved = Uint8List.fromList(
      Uint8List.sublistView(tiff, at + 12, ifdEnd),
    );
    for (var i = 0; i < moved.length; i++) {
      tiff.setUint8(at + i, moved[i]);
    }
    zero(ifdEnd - 12, ifdEnd);
    tiff.setUint16(ifd0, count - 1, order);
    return true;
  } on Object {
    return false;
  }
}
