import 'dart:typed_data';

import 'package:image/image.dart' as im;

import '../format.dart';

class PreparedPhoto {
  const PreparedPhoto({required this.jpeg, required this.takenAt});

  final Uint8List jpeg;

  /// Capture time from EXIF, when the file had one.
  final DateTime? takenAt;
}

class PhotoUnreadable implements Exception {
  const PhotoUnreadable();
}

const storedPhotoMaxSide = 1600;
const storedPhotoQuality = 82;

PreparedPhoto preparePhoto(Uint8List bytes) {
  try {
    final decoded = im.decodeImage(bytes);
    if (decoded == null) throw const PhotoUnreadable();
    final takenAt = _exifDate(decoded);
    final oriented = im.bakeOrientation(decoded);
    final fitted = _fitWithin(oriented, storedPhotoMaxSide);
    final jpeg = Uint8List.fromList(
      im.encodeJpg(fitted, quality: storedPhotoQuality),
    );
    return PreparedPhoto(jpeg: jpeg, takenAt: takenAt);
  } on PhotoUnreadable {
    rethrow;
  } catch (_) {
    throw const PhotoUnreadable();
  }
}

DateTime? _exifDate(im.Image image) {
  final raw =
      image.exif.exifIfd['DateTimeOriginal'] ?? image.exif.imageIfd['DateTime'];
  if (raw == null) return null;
  return parseExifDate(raw.toString());
}

im.Image _fitWithin(im.Image source, int maxSide) {
  if (source.width <= maxSide && source.height <= maxSide) return source;
  if (source.width >= source.height) {
    return im.copyResize(source, width: maxSide);
  }
  return im.copyResize(source, height: maxSide);
}
