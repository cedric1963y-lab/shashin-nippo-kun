import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shashin_nippo/data/repository.dart';
import 'package:shashin_nippo/models/records.dart';
import 'package:shashin_nippo/plan/entitlement.dart';
import 'package:shashin_nippo/plan/limits.dart';

void main() {
  late Directory directory;
  late Repository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nippo_repo_');
    repository = Repository(directory);
    await repository.init();
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('round-trips sites, photos, reports, and premium', () async {
    final site = JobSite(
      id: 'site-1',
      name: '南青山',
      note: '元請A',
      createdAt: DateTime(2026, 10, 7, 8),
    );
    await repository.saveSites([site]);
    await repository.writePhoto('p1.jpg', Uint8List.fromList([1, 2, 3]));
    await repository.savePhotos([
      SitePhoto(
        id: 'p1',
        siteId: 'site-1',
        fileName: 'p1.jpg',
        memo: '下地',
        takenAt: DateTime(2026, 10, 7, 9, 30),
      ),
    ]);
    await repository.saveReports([
      SavedReport(
        id: 'r1',
        siteId: 'site-1',
        siteName: '南青山',
        reportDate: DateTime(2026, 10, 7, 12),
        createdAt: DateTime(2026, 10, 7, 18),
        photoCount: 1,
        summary: '下地まで',
        pdfFileName: 'r1.pdf',
      ),
    ]);
    final expires = DateTime(2026, 11, 7, 9);
    await repository.saveEntitlement(
      Entitlement(productId: PlanLimits.monthlyProductId, expiresAt: expires),
    );

    final reopened = Repository(directory);
    final sites = await reopened.loadSites();
    final photos = await reopened.loadPhotos();
    final reports = await reopened.loadReports();
    expect(sites.single.name, '南青山');
    expect(photos.single.memo, '下地');
    expect(reports.single.summary, '下地まで');
    final entitlement = await reopened.loadEntitlement();
    expect(entitlement.productId, PlanLimits.monthlyProductId);
    expect(entitlement.expiresAt, expires);
    expect(entitlement.isActiveAt(DateTime(2026, 10, 7)), isTrue);
    expect(entitlement.isActiveAt(DateTime(2026, 12, 1)), isFalse);
    expect(await File(reopened.photoPath('p1.jpg')).readAsBytes(), [1, 2, 3]);
  });

  test('missing files mean an empty notebook', () async {
    expect(await repository.loadSites(), isEmpty);
    expect(await repository.loadPhotos(), isEmpty);
    expect(await repository.loadReports(), isEmpty);
    expect(
      (await repository.loadEntitlement()).isActiveAt(DateTime(2026, 10, 7)),
      isFalse,
    );
  });

  test(
    'a one-time flag without an expiry is not an active subscription',
    () async {
      await File('${directory.path}/entitlement.json')
          .writeAsString('{"version":1,"premium":true}');
      final entitlement = await repository.loadEntitlement();
      expect(entitlement.isActiveAt(DateTime(2026, 10, 7)), isFalse);
    },
  );
}
