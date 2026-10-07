import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as im;
import 'package:shashin_nippo/services/photo_codec.dart';

import 'support/harness.dart';

void main() {
  test('shrinks a wide photo and keeps a jpeg', () {
    final prepared = preparePhoto(tinyJpeg(width: 2000, height: 100));
    expect(prepared.jpeg[0], 0xFF);
    expect(prepared.jpeg[1], 0xD8);
    final decoded = im.decodeJpg(prepared.jpeg);
    expect(decoded, isNotNull);
    expect(decoded!.width, storedPhotoMaxSide);
    expect(decoded.height, lessThan(storedPhotoMaxSide));
    expect(prepared.takenAt, isNull);
  });

  test('reads DateTimeOriginal when the jpeg keeps it', () {
    final prepared = preparePhoto(tinyJpeg(exif: '2024:05:01 08:30:00'));
    expect(prepared.takenAt, DateTime(2024, 5, 1, 8, 30));
  });

  test('rejects bytes that are not an image', () {
    expect(
      () => preparePhoto(Uint8List.fromList(const [1, 2, 3, 4])),
      throwsA(isA<PhotoUnreadable>()),
    );
  });
}
