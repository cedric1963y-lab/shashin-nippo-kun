import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../models/records.dart';
import '../plan/entitlement.dart';

/// On-device JSON plus image and PDF files. No account and no network.
class Repository {
  Repository(this.root);

  final Directory root;

  static const _encoder = JsonEncoder.withIndent('  ');

  String get photoDirectory => p.join(root.path, 'photos');
  String get pdfDirectory => p.join(root.path, 'pdfs');

  String photoPath(String fileName) => p.join(photoDirectory, fileName);
  String pdfPath(String fileName) => p.join(pdfDirectory, fileName);

  Future<void> init() async {
    await root.create(recursive: true);
    await Directory(photoDirectory).create(recursive: true);
    await Directory(pdfDirectory).create(recursive: true);
  }

  Future<List<JobSite>> loadSites() {
    return _loadList('sites.json', 'sites', JobSite.fromJson);
  }

  Future<void> saveSites(List<JobSite> sites) {
    return _saveList('sites.json', 'sites', [
      for (final site in sites) site.toJson(),
    ]);
  }

  Future<List<SitePhoto>> loadPhotos() {
    return _loadList('photos.json', 'photos', SitePhoto.fromJson);
  }

  Future<void> savePhotos(List<SitePhoto> photos) {
    return _saveList('photos.json', 'photos', [
      for (final photo in photos) photo.toJson(),
    ]);
  }

  Future<List<SavedReport>> loadReports() {
    return _loadList('reports.json', 'reports', SavedReport.fromJson);
  }

  Future<void> saveReports(List<SavedReport> reports) {
    return _saveList('reports.json', 'reports', [
      for (final report in reports) report.toJson(),
    ]);
  }

  Future<Entitlement> loadEntitlement() async {
    final json = await _readObject('entitlement.json');
    return Entitlement.fromJson(json);
  }

  Future<void> saveEntitlement(Entitlement entitlement) {
    return _atomicWrite(
      'entitlement.json',
      _encoder.convert(entitlement.toJson()),
    );
  }

  Future<void> writePhoto(String fileName, Uint8List bytes) async {
    final file = File(photoPath(fileName));
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> writePdf(String fileName, Uint8List bytes) async {
    final file = File(pdfPath(fileName));
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<T>> _loadList<T>(
    String name,
    String key,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final json = await _readObject(name);
    if (json == null) return [];
    final list = json[key];
    if (list is! List) return [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          parse(item)
        else if (item is Map)
          parse(Map<String, dynamic>.from(item)),
    ];
  }

  Future<void> _saveList(
    String name,
    String key,
    List<Map<String, dynamic>> items,
  ) {
    return _atomicWrite(name, _encoder.convert({'version': 1, key: items}));
  }

  Future<Map<String, dynamic>?> _readObject(String name) async {
    final file = File(p.join(root.path, name));
    if (!await file.exists()) return null;
    final text = await file.readAsString();
    if (text.trim().isEmpty) return null;
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('保存データの形式が不正です。');
    }
    final json = Map<String, dynamic>.from(decoded);
    final version = json['version'];
    if (version != 1) {
      throw FormatException('未対応の保存データです（version: $version）。');
    }
    return json;
  }

  Future<void> _atomicWrite(String name, String contents) async {
    final target = File(p.join(root.path, name));
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(target.path);
  }
}
