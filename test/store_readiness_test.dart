import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as im;
import 'package:shashin_nippo/plan/limits.dart';

void main() {
  test('Info.plist asks for camera and photos in Japanese', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('NSCameraUsageDescription'));
    expect(plist, contains('NSPhotoLibraryUsageDescription'));
    expect(plist, contains('このiPhoneの中だけに保存されます'));
    expect(plist, contains('写真日報くん'));
    expect(plist, contains('<key>ITSAppUsesNonExemptEncryption</key>'));
    expect(plist, contains('<false/>'));
    expect(plist, isNot(contains('NSPhotoLibraryAddUsageDescription')));
  });

  test('privacy manifest declares no tracking and no collected data', () {
    final privacy = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
    expect(privacy, contains('<key>NSPrivacyTracking</key>'));
    expect(privacy, contains('<false/>'));
    expect(privacy, contains('<key>NSPrivacyCollectedDataTypes</key>'));
    expect(privacy, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(privacy, contains('CA92.1'));
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
    expect(
      project,
      contains('PRODUCT_BUNDLE_IDENTIFIER = ${PlanLimits.bundleId};'),
    );
    expect(project, contains('TARGETED_DEVICE_FAMILY = "1";'));
    expect(project, isNot(contains('TARGETED_DEVICE_FAMILY = "1,2"')));
    expect(
      File('ios/Runner/Info.plist').readAsStringSync(),
      isNot(contains('UISupportedInterfaceOrientations~ipad')),
    );
  });

  test('StoreKit config is the premium subscription group', () {
    final store = File('ios/Runner/Products.storekit').readAsStringSync();
    expect(store, contains(PlanLimits.monthlyProductId));
    expect(store, contains(PlanLimits.yearlyProductId));
    expect(store, contains('RecurringSubscription'));
    expect(store, contains('P1M'));
    expect(store, contains('P1Y'));
    expect(store, contains('"displayPrice" : "100"'));
    expect(store, contains('"displayPrice" : "1200"'));
    expect(store, isNot(contains('NonConsumable')));
    final scheme = File(
      'ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    ).readAsStringSync();
    expect(scheme, contains('Runner/Products.storekit'));
  });

  test('app icon is a full-bleed 1024 image, not a flat placeholder', () {
    final bytes = File('assets/icon/app_icon.png').readAsBytesSync();
    final icon = im.decodePng(bytes);
    expect(icon, isNotNull);
    expect(icon!.width, 1024);
    expect(icon.height, 1024);
    final corner = icon.getPixel(0, 0);
    final center = icon.getPixel(512, 512);
    final different =
        corner.r != center.r || corner.g != center.g || corner.b != center.b;
    expect(different, isTrue);
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      ).existsSync(),
      isTrue,
    );
  });
}
