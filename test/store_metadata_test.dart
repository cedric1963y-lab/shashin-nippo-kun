import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shashin_nippo/plan/limits.dart';

void main() {
  test('Japanese metadata fits App Store field limits', () {
    final metadata = File('store/metadata-ja.md').readAsStringSync();
    final fields = _sections(metadata);

    expect(fields['名前'], '写真日報くん');
    expect(fields['名前']!.length, lessThanOrEqualTo(30));
    expect(fields['サブタイトル']!.length, inInclusiveRange(1, 30));
    expect(fields['キーワード']!.length, inInclusiveRange(1, 100));
    expect(fields['キーワード'], isNot(contains(' ')));
    expect(fields['プロモーションテキスト']!.length, inInclusiveRange(1, 170));
    expect(fields['概要']!.length, inInclusiveRange(1, 4000));
    expect(fields['新機能']!.length, inInclusiveRange(1, 4000));
    expect(fields['概要'], contains('一人親方'));
    expect(fields['概要'], contains('3件'));
    expect(fields['概要'], contains('20枚'));
    expect(fields['概要'], contains('広告はありません'));

    final checklist = File('store/submission-checklist.md').readAsStringSync();
    expect(checklist, contains(PlanLimits.bundleId));
    expect(checklist, contains(PlanLimits.monthlyProductId));
    expect(checklist, contains(PlanLimits.yearlyProductId));
    expect(checklist, contains('プロモーション用画像は付けない'));

    final privacy = File('docs/privacy.html').readAsStringSync();
    final terms = File('docs/terms.html').readAsStringSync();
    final support = File('docs/index.html').readAsStringSync();
    expect(privacy, contains('この iPhone の中だけに保存します'));
    expect(privacy, contains('アカウントはありません'));
    expect(privacy, contains('広告 SDK は入れていません'));
    expect(privacy, contains('AdMob'));
    expect(privacy, contains('トラッキングはしません'));
    expect(terms, contains('月額: ¥100（1か月）'));
    expect(terms, contains('年額: ¥1,200（1年）'));
    expect(terms, contains('新しく作れる日報は3件、保存できる写真は20枚'));
    expect(support, contains('href="privacy.html"'));
    expect(support, contains('href="terms.html"'));
  });

  test('the binary has no ad SDK and keeps the privacy manifest', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final privacy = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
    final sources = [
      pubspec,
      plist,
      privacy,
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
    ].join('\n');

    expect(pubspec, isNot(contains('google_mobile_ads')));
    expect(sources, isNot(contains('GADApplicationIdentifier')));
    expect(plist, isNot(contains('NSUserTrackingUsageDescription')));
    expect(privacy, contains('<key>NSPrivacyCollectedDataTypes</key>'));
    expect(privacy, contains('<array/>'));
    expect(plist, contains('NSCameraUsageDescription'));
    expect(plist, contains('NSPhotoLibraryUsageDescription'));
    expect(
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
      contains('PRODUCT_BUNDLE_IDENTIFIER = ${PlanLimits.bundleId};'),
    );
    expect(
      File('ios/Runner/Products.storekit').readAsStringSync(),
      contains(PlanLimits.monthlyProductId),
    );
    expect(
      File('tool/capture_app_store_screenshots.sh').readAsStringSync(),
      contains('simctl io booted screenshot'),
    );
  });
}

Map<String, String> _sections(String markdown) {
  final fields = <String, String>{};
  String? name;
  final body = StringBuffer();
  void flush() {
    if (name == null) return;
    fields[name!] = body.toString().trim();
    body.clear();
  }

  for (final line in markdown.split('\n')) {
    if (line.startsWith('## ')) {
      flush();
      name = line.substring(3).trim();
      continue;
    }
    if (name != null) {
      body.writeln(line);
    }
  }
  flush();
  return fields;
}
