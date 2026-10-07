import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shashin_nippo/data/repository.dart';
import 'package:shashin_nippo/errors.dart';
import 'package:shashin_nippo/models/records.dart';
import 'package:shashin_nippo/plan/entitlement.dart';
import 'package:shashin_nippo/plan/limits.dart';
import 'package:shashin_nippo/services/purchase_gateway.dart';

import 'support/fake_purchase_gateway.dart';
import 'support/harness.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nippo_app_');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('free plan blocks the 21st photo and the 4th report', () async {
    final controller = await openController(directory);
    final site = await controller.addSite(name: '現場A');
    expect(controller.canAddPhoto, isTrue);
    expect(controller.canCreateReport, isTrue);

    final seededPhotos = [
      for (var i = 0; i < PlanLimits.freePhotoLimit; i++)
        SitePhoto(
          id: 'p$i',
          siteId: site.id,
          fileName: 'p$i.jpg',
          memo: '',
          takenAt: DateTime(2026, 10, 1, 9, i),
        ),
    ];
    await controller.repository.savePhotos(seededPhotos);
    await controller.load();
    expect(controller.canAddPhoto, isFalse);
    await expectLater(
      controller.addPhoto(
        siteId: site.id,
        bytes: tinyJpeg(),
        memo: '',
        takenAt: DateTime(2026, 10, 7, 10),
      ),
      throwsA(
        isA<LimitReached>().having(
          (error) => error.kind,
          'kind',
          LimitKind.photos,
        ),
      ),
    );

    final seededReports = [
      for (var i = 0; i < PlanLimits.freeReportLimit; i++)
        SavedReport(
          id: 'r$i',
          siteId: site.id,
          siteName: site.name,
          reportDate: DateTime(2026, 10, i + 1, 12),
          createdAt: DateTime(2026, 10, i + 1, 18),
          photoCount: 1,
          summary: '',
          pdfFileName: 'r$i.pdf',
        ),
    ];
    await controller.repository.saveReports(seededReports);
    await controller.load();
    expect(controller.canCreateReport, isFalse);
    await expectLater(
      controller.createReport(
        siteId: site.id,
        reportDate: DateTime(2026, 10, 7),
        summary: '',
        photoIds: const ['p0'],
      ),
      throwsA(
        isA<LimitReached>().having(
          (error) => error.kind,
          'kind',
          LimitKind.reports,
        ),
      ),
    );

    await controller.deleteReport('r0');
    expect(controller.canCreateReport, isTrue);
    await controller.deletePhoto('p0');
    expect(controller.canAddPhoto, isTrue);
  });

  test('premium stores a photo and a shareable pdf', () async {
    final controller = await openController(directory, premium: true);
    final site = await controller.addSite(name: '南/青山', note: '元請');
    final photo = await controller.addPhoto(
      siteId: site.id,
      bytes: tinyJpeg(),
      memo: '外壁下地、2階南側',
      takenAt: DateTime(2026, 10, 7, 9, 30),
    );
    expect(await File(controller.photoPath(photo)).exists(), isTrue);

    final report = await controller.createReport(
      siteId: site.id,
      reportDate: DateTime(2026, 10, 7, 15),
      summary: '下地まで完了',
      photoIds: [photo.id],
    );
    final pdf = await File(controller.reportPath(report)).readAsBytes();
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(pdf.length, greaterThan(2000));
    expect(pdf.length, lessThan(1500000));
    expect(controller.shareFileName(report), contains('南青山'));
    expect(controller.reports, hasLength(1));

    final reopened = await openController(directory, premium: true);
    expect(reopened.sites.single.name, '南/青山');
    expect(reopened.photos.single.memo, '外壁下地、2階南側');
    expect(reopened.premium, isTrue);
    reopened.dispose();
    controller.dispose();
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('purchase unlock is stored until it expires', () async {
    final gateway = FakePurchaseGateway();
    final controller = await openController(directory, purchases: gateway);
    expect(controller.premium, isFalse);
    await gateway.emit(
      PurchaseEvent.unlocked(
        productId: PlanLimits.monthlyProductId,
        expiresAt: DateTime.now().add(const Duration(days: 28)),
      ),
    );
    expect(controller.premium, isTrue);
    expect(controller.entitlement.productId, PlanLimits.monthlyProductId);
    expect(
      (await controller.repository.loadEntitlement()).isActiveAt(
        DateTime.now(),
      ),
      isTrue,
    );

    await controller.buyPlan(PlanLimits.monthlyProductId);
    expect(gateway.buys, 0);
    await controller.buyPlan(PlanLimits.yearlyProductId);
    expect(gateway.buys, 1);
    expect(gateway.lastProductId, PlanLimits.yearlyProductId);

    final again = await openController(directory);
    expect(again.premium, isTrue);
    again.dispose();
    controller.dispose();
  });

  test('an expired renewal does not unlock', () async {
    final gateway = FakePurchaseGateway();
    final controller = await openController(directory, purchases: gateway);
    await gateway.emit(
      PurchaseEvent.unlocked(
        productId: PlanLimits.monthlyProductId,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );
    expect(controller.premium, isFalse);
    expect((await controller.repository.loadEntitlement()).expiresAt, isNull);
    controller.dispose();
  });

  test('expired premium keeps photos and restores the free cap', () async {
    final repository = Repository(directory);
    await repository.init();
    await repository.saveSites([
      JobSite(
        id: 'site-1',
        name: '現場A',
        note: '',
        createdAt: DateTime(2026, 10, 1),
      ),
    ]);
    await repository.writePhoto('keep.jpg', tinyJpeg());
    await repository.savePhotos([
      for (var i = 0; i < PlanLimits.freePhotoLimit; i++)
        SitePhoto(
          id: 'p$i',
          siteId: 'site-1',
          fileName: i == 0 ? 'keep.jpg' : 'p$i.jpg',
          memo: '',
          takenAt: DateTime(2026, 10, 1, 9, i),
        ),
    ]);
    await repository.saveEntitlement(
      Entitlement(
        productId: PlanLimits.yearlyProductId,
        expiresAt: DateTime(2020, 1, 1),
      ),
    );

    final controller = await openController(directory);
    expect(controller.premium, isFalse);
    expect(controller.sites.single.name, '現場A');
    expect(controller.photos, hasLength(PlanLimits.freePhotoLimit));
    expect(
      await File(controller.photoPath(controller.photos.first)).exists(),
      isTrue,
    );
    expect(controller.canAddPhoto, isFalse);
    controller.dispose();
  });

  test(
    'an empty store answer locks premium and keeps the photo file',
    () async {
      final repository = Repository(directory);
      await repository.init();
      await repository.saveSites([
        JobSite(
          id: 'site-1',
          name: '現場A',
          note: '',
          createdAt: DateTime(2026, 10, 1),
        ),
      ]);
      await repository.writePhoto('keep.jpg', tinyJpeg());
      await repository.savePhotos([
        SitePhoto(
          id: 'p0',
          siteId: 'site-1',
          fileName: 'keep.jpg',
          memo: '足場',
          takenAt: DateTime(2026, 10, 1, 9),
        ),
      ]);
      await repository.saveEntitlement(
        Entitlement(
          productId: PlanLimits.monthlyProductId,
          expiresAt: DateTime.now().add(const Duration(days: 10)),
        ),
      );

      final gateway = FakePurchaseGateway()..subscriptions = [];
      final controller = await openController(directory, purchases: gateway);
      expect(controller.premium, isFalse);
      expect(controller.sites.single.name, '現場A');
      expect(controller.photos.single.memo, '足場');
      expect(await File(repository.photoPath('keep.jpg')).exists(), isTrue);
      expect(
        (await repository.loadEntitlement()).isActiveAt(DateTime.now()),
        isFalse,
      );
      controller.dispose();
    },
  );

  test('empty site name is rejected', () async {
    final controller = await openController(directory);
    await expectLater(
      controller.addSite(name: '   '),
      throwsA(isA<InvalidInput>()),
    );
    controller.dispose();
  });
}
