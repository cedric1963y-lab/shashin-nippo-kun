import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../errors.dart';
import '../format.dart';
import '../ids.dart';
import '../models/records.dart';
import '../plan/entitlement.dart';
import '../plan/limits.dart';
import '../services/pdf_report.dart';
import '../services/photo_codec.dart';
import '../services/purchase_gateway.dart';

enum PurchasePhase { idle, pending, error }

class AppController extends ChangeNotifier {
  AppController({
    required this.repository,
    required this.purchases,
    Future<ByteData> Function()? loadFont,
    DateTime Function()? now,
  }) : _loadFont = loadFont ?? _loadBundledFont,
       _now = now ?? DateTime.now;

  final Repository repository;
  final PurchaseGateway purchases;
  final Future<ByteData> Function() _loadFont;
  final DateTime Function() _now;

  List<JobSite> sites = [];
  List<SitePhoto> photos = [];
  List<SavedReport> reports = [];
  Entitlement entitlement = const Entitlement();
  PurchasePhase purchasePhase = PurchasePhase.idle;
  String? purchaseError;
  List<StoreProduct> storeProducts = [];
  ByteData? _font;

  bool get premium => entitlement.isActiveAt(_now());

  bool get canAddPhoto =>
      PlanLimits.canAddPhoto(premium: premium, photoCount: photos.length);

  bool get canCreateReport =>
      PlanLimits.canCreateReport(premium: premium, reportCount: reports.length);

  String priceFor(String productId) {
    for (final product in storeProducts) {
      if (product.id == productId) return product.priceLabel;
    }
    return PlanLimits.priceLabelFor(productId);
  }

  Future<void> load() async {
    await repository.init();
    sites = await repository.loadSites();
    photos = await repository.loadPhotos();
    reports = await repository.loadReports();
    entitlement = await repository.loadEntitlement();
    try {
      await purchases.start(_onPurchase);
      await _applyStoreSubscriptions();
    } catch (_) {
      // Reports still work when StoreKit cannot start.
    }
    notifyListeners();
  }

  Future<void> _applyStoreSubscriptions() async {
    final found = await purchases.currentSubscriptions();
    if (found == null) return;
    final active = activeSubscription(found, _now());
    if (active == null) {
      entitlement = const Entitlement();
    } else {
      entitlement = Entitlement(
        productId: active.productId,
        expiresAt: active.expiresAt,
      );
    }
    await repository.saveEntitlement(entitlement);
  }

  List<JobSite> get sitesByRecent {
    final copy = [...sites];
    copy.sort((a, b) => lastActivity(b).compareTo(lastActivity(a)));
    return copy;
  }

  DateTime lastActivity(JobSite site) {
    var latest = site.createdAt;
    for (final photo in photosFor(site.id)) {
      if (photo.takenAt.isAfter(latest)) latest = photo.takenAt;
    }
    for (final report in reportsFor(site.id)) {
      if (report.createdAt.isAfter(latest)) latest = report.createdAt;
    }
    return latest;
  }

  List<SitePhoto> photosFor(String siteId) {
    final list = photos.where((photo) => photo.siteId == siteId).toList();
    list.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return list;
  }

  List<SavedReport> reportsFor(String siteId) {
    final list = reports.where((report) => report.siteId == siteId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  JobSite? siteById(String id) {
    for (final site in sites) {
      if (site.id == id) return site;
    }
    return null;
  }

  SitePhoto? photoById(String id) {
    for (final photo in photos) {
      if (photo.id == id) return photo;
    }
    return null;
  }

  int photoCountFor(String siteId) => photosFor(siteId).length;

  int reportCountFor(String siteId) => reportsFor(siteId).length;

  String photoPath(SitePhoto photo) => repository.photoPath(photo.fileName);

  String reportPath(SavedReport report) =>
      repository.pdfPath(report.pdfFileName);

  String shareFileName(SavedReport report) {
    final site = siteById(report.siteId);
    return reportShareFileName(
      siteName: site?.name ?? report.siteName,
      reportDate: report.reportDate,
    );
  }

  Future<JobSite> addSite({required String name, String note = ''}) async {
    final site = JobSite(
      id: createId(),
      name: _requiredLine(name, '現場名', 40),
      note: _optionalLine(note, 80),
      createdAt: DateTime.now(),
    );
    sites = [...sites, site];
    await repository.saveSites(sites);
    notifyListeners();
    return site;
  }

  Future<void> updateSite({
    required String id,
    required String name,
    String note = '',
  }) async {
    final index = sites.indexWhere((site) => site.id == id);
    if (index < 0) throw const InvalidInput('現場が見つかりません。');
    sites = [...sites];
    sites[index] = sites[index].copyWith(
      name: _requiredLine(name, '現場名', 40),
      note: _optionalLine(note, 80),
    );
    await repository.saveSites(sites);
    notifyListeners();
  }

  Future<void> deleteSite(String id) async {
    final photoFiles = [
      for (final photo in photos)
        if (photo.siteId == id) repository.photoPath(photo.fileName),
    ];
    final pdfFiles = [
      for (final report in reports)
        if (report.siteId == id) repository.pdfPath(report.pdfFileName),
    ];
    sites = sites.where((site) => site.id != id).toList();
    photos = photos.where((photo) => photo.siteId != id).toList();
    reports = reports.where((report) => report.siteId != id).toList();
    await repository.saveSites(sites);
    await repository.savePhotos(photos);
    await repository.saveReports(reports);
    for (final path in [...photoFiles, ...pdfFiles]) {
      await repository.deleteFileIfExists(path);
    }
    notifyListeners();
  }

  Future<SitePhoto> addPhoto({
    required String siteId,
    required Uint8List bytes,
    required String memo,
    required DateTime takenAt,
  }) async {
    if (siteById(siteId) == null) {
      throw const InvalidInput('現場が見つかりません。');
    }
    if (!canAddPhoto) throw const LimitReached(LimitKind.photos);
    final prepared = preparePhoto(bytes);
    final photo = SitePhoto(
      id: createId(),
      siteId: siteId,
      fileName: '',
      memo: _optionalLine(memo, 80),
      takenAt: takenAt,
    );
    final stored = SitePhoto(
      id: photo.id,
      siteId: photo.siteId,
      fileName: '${photo.id}.jpg',
      memo: photo.memo,
      takenAt: photo.takenAt,
    );
    await repository.writePhoto(stored.fileName, prepared.jpeg);
    photos = [...photos, stored];
    try {
      await repository.savePhotos(photos);
    } catch (error) {
      await repository.deleteFileIfExists(
        repository.photoPath(stored.fileName),
      );
      photos = photos.where((item) => item.id != stored.id).toList();
      rethrow;
    }
    notifyListeners();
    return stored;
  }

  Future<void> updatePhoto({
    required String id,
    required String memo,
    required DateTime takenAt,
  }) async {
    final index = photos.indexWhere((photo) => photo.id == id);
    if (index < 0) throw const InvalidInput('写真が見つかりません。');
    photos = [...photos];
    photos[index] = photos[index].copyWith(
      memo: _optionalLine(memo, 80),
      takenAt: takenAt,
    );
    await repository.savePhotos(photos);
    notifyListeners();
  }

  Future<void> deletePhoto(String id) async {
    final photo = photoById(id);
    if (photo == null) return;
    photos = photos.where((item) => item.id != id).toList();
    await repository.savePhotos(photos);
    await repository.deleteFileIfExists(repository.photoPath(photo.fileName));
    notifyListeners();
  }

  Future<SavedReport> createReport({
    required String siteId,
    required DateTime reportDate,
    required String summary,
    required List<String> photoIds,
  }) async {
    final site = siteById(siteId);
    if (site == null) throw const InvalidInput('現場が見つかりません。');
    if (!canCreateReport) throw const LimitReached(LimitKind.reports);

    final chosen = <SitePhoto>[];
    for (final id in photoIds) {
      final photo = photoById(id);
      if (photo == null || photo.siteId != siteId) {
        throw const InvalidInput('選択した写真が見つかりません。');
      }
      chosen.add(photo);
    }
    if (chosen.isEmpty) {
      throw const InvalidInput('写真を1枚以上選んでください。');
    }
    if (chosen.length > PlanLimits.maxPhotosPerReport) {
      throw const LimitReached(LimitKind.photosPerReport);
    }
    chosen.sort((a, b) => a.takenAt.compareTo(b.takenAt));

    final pdfPhotos = <PdfPhoto>[];
    for (final photo in chosen) {
      final file = File(repository.photoPath(photo.fileName));
      if (!await file.exists()) {
        throw const InvalidInput('写真ファイルが見つかりません。その写真を削除して、もう一度追加してください。');
      }
      pdfPhotos.add(
        PdfPhoto(
          bytes: await file.readAsBytes(),
          memo: photo.memo,
          takenAt: photo.takenAt,
        ),
      );
    }

    final cleanedSummary = _optionalLine(summary, 120);
    final bytes = await buildDailyReportPdf(
      fontData: await _fontData(),
      siteName: site.name,
      siteNote: site.note,
      reportDate: dateOnly(reportDate),
      summary: cleanedSummary,
      photos: pdfPhotos,
    );

    final report = SavedReport(
      id: createId(),
      siteId: site.id,
      siteName: site.name,
      reportDate: dateOnly(reportDate),
      createdAt: DateTime.now(),
      photoCount: chosen.length,
      summary: cleanedSummary,
      pdfFileName: '',
    );
    final stored = SavedReport(
      id: report.id,
      siteId: report.siteId,
      siteName: report.siteName,
      reportDate: report.reportDate,
      createdAt: report.createdAt,
      photoCount: report.photoCount,
      summary: report.summary,
      pdfFileName: '${report.id}.pdf',
    );
    await repository.writePdf(stored.pdfFileName, bytes);
    reports = [...reports, stored];
    try {
      await repository.saveReports(reports);
    } catch (error) {
      await repository.deleteFileIfExists(
        repository.pdfPath(stored.pdfFileName),
      );
      reports = reports.where((item) => item.id != stored.id).toList();
      rethrow;
    }
    notifyListeners();
    return stored;
  }

  Future<void> deleteReport(String id) async {
    SavedReport? report;
    for (final item in reports) {
      if (item.id == id) {
        report = item;
        break;
      }
    }
    if (report == null) return;
    reports = reports.where((item) => item.id != id).toList();
    await repository.saveReports(reports);
    await repository.deleteFileIfExists(repository.pdfPath(report.pdfFileName));
    notifyListeners();
  }

  Future<void> refreshProduct() async {
    try {
      storeProducts = await purchases.loadProducts();
    } catch (_) {
      storeProducts = [];
    }
    notifyListeners();
  }

  Future<void> buyPlan(String productId) async {
    if (purchasePhase == PurchasePhase.pending) return;
    if (!PlanLimits.isPremiumProduct(productId)) return;
    if (premium && entitlement.productId == productId) return;
    purchasePhase = PurchasePhase.pending;
    purchaseError = null;
    notifyListeners();
    try {
      await purchases.buy(productId);
    } on StoreUnavailable catch (error) {
      purchasePhase = PurchasePhase.error;
      purchaseError = error.message;
      notifyListeners();
    } catch (_) {
      purchasePhase = PurchasePhase.error;
      purchaseError = '購入を開始できませんでした。通信状況を確認してください。';
      notifyListeners();
    }
  }

  Future<void> restorePremium() async {
    if (purchasePhase == PurchasePhase.pending) return;
    purchasePhase = PurchasePhase.pending;
    purchaseError = null;
    notifyListeners();
    final already = premium;
    try {
      await purchases.restore();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (purchasePhase == PurchasePhase.pending && !premium && !already) {
        purchasePhase = PurchasePhase.error;
        purchaseError = '復元できる契約は見つかりませんでした。契約したApple IDでサインインしているか確認してください。';
      } else if (purchasePhase == PurchasePhase.pending) {
        purchasePhase = PurchasePhase.idle;
      }
    } on StoreUnavailable catch (error) {
      purchasePhase = PurchasePhase.error;
      purchaseError = error.message;
    } catch (_) {
      purchasePhase = PurchasePhase.error;
      purchaseError = '復元できませんでした。通信状況を確認してください。';
    }
    notifyListeners();
  }

  Future<void> _onPurchase(PurchaseEvent event) async {
    switch (event.kind) {
      case PurchaseEventKind.unlocked:
        final productId = event.productId;
        final expiresAt = event.expiresAt;
        if (productId == null ||
            expiresAt == null ||
            !PlanLimits.isPremiumProduct(productId) ||
            !expiresAt.isAfter(_now())) {
          purchasePhase = PurchasePhase.error;
          purchaseError = '有効な契約は見つかりませんでした。期限が切れている場合は、月額または年額を開始してください。';
          break;
        }
        entitlement = Entitlement(productId: productId, expiresAt: expiresAt);
        purchasePhase = PurchasePhase.idle;
        purchaseError = null;
        try {
          await repository.saveEntitlement(entitlement);
        } catch (_) {
          purchasePhase = PurchasePhase.error;
          purchaseError = '契約は確認できましたが、端末への保存に失敗しました。この画面を開いたまま、もう一度お試しください。';
        }
      case PurchaseEventKind.pending:
        purchasePhase = PurchasePhase.pending;
        purchaseError = null;
      case PurchaseEventKind.canceled:
        if (purchasePhase == PurchasePhase.pending) {
          purchasePhase = PurchasePhase.idle;
        }
      case PurchaseEventKind.error:
        purchasePhase = PurchasePhase.error;
        purchaseError = event.message ?? '購入できませんでした。';
    }
    notifyListeners();
  }

  Future<ByteData> _fontData() async {
    return _font ??= await _loadFont();
  }

  static Future<ByteData> _loadBundledFont() {
    return rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
  }

  String _requiredLine(String input, String label, int max) {
    final text = collapseWhitespace(input);
    if (text.isEmpty) throw InvalidInput('$labelを入力してください。');
    if (text.length > max) throw InvalidInput('$labelは$max文字までです。');
    return text;
  }

  String _optionalLine(String input, int max) {
    final text = collapseWhitespace(input);
    if (text.length > max) {
      throw InvalidInput('$max文字までにしてください。');
    }
    return text;
  }

  @override
  void dispose() {
    purchases.dispose();
    super.dispose();
  }
}
