import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as im;
import 'package:shashin_nippo/data/repository.dart';
import 'package:shashin_nippo/plan/entitlement.dart';
import 'package:shashin_nippo/plan/limits.dart';
import 'package:shashin_nippo/services/purchase_gateway.dart';
import 'package:shashin_nippo/state/app_controller.dart';

import 'fake_purchase_gateway.dart';

Future<ByteData> loadTestFont() async {
  final bytes = await File('assets/fonts/NotoSansJP-Regular.ttf').readAsBytes();
  return ByteData.sublistView(bytes);
}

Future<AppController> openController(
  Directory directory, {
  bool premium = false,
  PurchaseGateway? purchases,
}) async {
  final repository = Repository(directory);
  await repository.init();
  if (premium) {
    await repository.saveEntitlement(
      Entitlement(
        productId: PlanLimits.monthlyProductId,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
    );
  }
  final controller = AppController(
    repository: repository,
    purchases: purchases ?? FakePurchaseGateway(),
    loadFont: loadTestFont,
  );
  await controller.load();
  return controller;
}

Uint8List tinyJpeg({int width = 24, int height = 16, String? exif}) {
  final image = im.Image(width: width, height: height);
  im.fill(image, color: im.ColorRgb8(220, 90, 30));
  if (exif != null) {
    image.exif.exifIfd['DateTimeOriginal'] = exif;
  }
  return Uint8List.fromList(im.encodeJpg(image, quality: 90));
}
