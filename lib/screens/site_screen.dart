import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_scope.dart';
import '../format.dart';
import '../models/records.dart';
import '../services/photo_codec.dart';
import '../services/share_pdf.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import 'photo_editor_screen.dart';
import 'report_screen.dart';

class SiteScreen extends StatefulWidget {
  const SiteScreen({required this.siteId, super.key});

  final String siteId;

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

enum _SitePane { photos, reports }

class _SiteScreenState extends State<SiteScreen> {
  _SitePane _pane = _SitePane.photos;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final site = controller.siteById(widget.siteId);
    if (site == null) {
      return const Scaffold(body: Center(child: Text('この現場は削除されました。')));
    }
    final photos = controller.photosFor(site.id);
    final reports = controller.reportsFor(site.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(site.name, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            tooltip: '現場メニュー',
            onSelected: (value) {
              if (value == 'edit') {
                _editSite();
              } else if (value == 'delete') {
                _deleteSite();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('現場を編集')),
              PopupMenuItem(value: 'delete', child: Text('現場を削除')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (site.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      site.note,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                SegmentedButton<_SitePane>(
                  segments: [
                    ButtonSegment(
                      value: _SitePane.photos,
                      label: Text('写真 ${photos.length}'),
                    ),
                    ButtonSegment(
                      value: _SitePane.reports,
                      label: Text('日報 ${reports.length}'),
                    ),
                  ],
                  selected: {_pane},
                  onSelectionChanged: (value) =>
                      setState(() => _pane = value.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: _pane == _SitePane.photos
                ? _PhotoPane(
                    empty: photos.isEmpty,
                    children: [
                      for (final photo in photos)
                        _PhotoTile(
                          path: controller.photoPath(photo),
                          time: formatTime(photo.takenAt),
                          memo: photo.memo,
                          onTap: () => _editPhoto(photo.id),
                        ),
                    ],
                  )
                : _ReportPane(
                    reports: [
                      for (final report in reports)
                        _ReportTile(
                          title: formatJapaneseDate(report.reportDate),
                          detail: [
                            '写真 ${report.photoCount}枚',
                            if (report.summary.isNotEmpty) report.summary,
                          ].join(' · '),
                          onShare: (origin) => _shareReport(report.id, origin),
                          onDelete: () => _deleteReport(report.id),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: AppColors.card,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: photos.isEmpty ? null : _openReport,
                    child: const Text('日報を作る'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _chooseSource,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('写真を追加'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editSite() async {
    final controller = AppScope.of(context);
    final site = controller.siteById(widget.siteId);
    if (site == null) return;
    final draft = await showSiteDialog(
      context,
      title: '現場を編集',
      saveLabel: '保存',
      initialName: site.name,
      initialNote: site.note,
    );
    if (draft == null || !mounted) return;
    try {
      await controller.updateSite(
        id: site.id,
        name: draft.name,
        note: draft.note,
      );
    } catch (error) {
      if (mounted) await handleLimitOrMessage(context, error);
    }
  }

  Future<void> _deleteSite() async {
    final controller = AppScope.of(context);
    final site = controller.siteById(widget.siteId);
    if (site == null) return;
    final ok = await confirmAction(
      context,
      title: '現場を削除しますか？',
      body: '「${site.name}」の写真と日報PDFも、このiPhoneから消えます。すでに共有したファイルは戻りません。',
      confirmLabel: '削除',
    );
    if (!ok || !mounted) return;
    await controller.deleteSite(site.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('カメラで撮る'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('ライブラリから選ぶ'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 92,
        requestFullMetadata: true,
      );
      if (file == null || !mounted) return;
      final raw = await file.readAsBytes();
      if (!mounted) return;
      final controller = AppScope.of(context);
      final prepared = await runBlocking(context, '写真を読み込んでいます', () async {
        return preparePhoto(raw);
      });
      if (!mounted) return;
      final result = await Navigator.of(context).push<PhotoEditorResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PhotoEditorScreen(
            title: '写真を追加',
            image: MemoryImage(prepared.jpeg),
            initialTakenAt: prepared.takenAt ?? DateTime.now(),
            initialMemo: '',
            saveLabel: 'この写真を保存',
          ),
        ),
      );
      if (result == null || result.deleted || !mounted) return;
      await runBlocking(context, '写真を保存しています', () async {
        await controller.addPhoto(
          siteId: widget.siteId,
          bytes: prepared.jpeg,
          memo: result.memo,
          takenAt: result.takenAt ?? DateTime.now(),
        );
      });
    } on PhotoUnreadable {
      if (mounted) {
        await showSnack(context, 'この写真は読み込めませんでした。別の写真を選んでください。');
      }
    } on PlatformException catch (error) {
      if (mounted) await showSnack(context, _pickError(error));
    } catch (error) {
      if (mounted) await handleLimitOrMessage(context, error);
    }
  }

  String _pickError(PlatformException error) {
    final code = error.code;
    if (code.contains('camera')) {
      return 'カメラを使えません。設定アプリで「写真日報くん」のカメラを許可してください。';
    }
    if (code.contains('photo') ||
        code.contains('denied') ||
        code.contains('restricted')) {
      return '写真を読み込めません。設定アプリで「写真日報くん」の写真アクセスを許可してください。';
    }
    return '写真を追加できませんでした。';
  }

  Future<void> _editPhoto(String photoId) async {
    final controller = AppScope.of(context);
    final photo = controller.photoById(photoId);
    if (photo == null) return;
    final result = await Navigator.of(context).push<PhotoEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoEditorScreen(
          title: '写真を編集',
          image: FileImage(File(controller.photoPath(photo))),
          initialTakenAt: photo.takenAt,
          initialMemo: photo.memo,
          saveLabel: '保存する',
          allowDelete: true,
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (result.deleted) {
        await controller.deletePhoto(photo.id);
        return;
      }
      await controller.updatePhoto(
        id: photo.id,
        memo: result.memo,
        takenAt: result.takenAt ?? photo.takenAt,
      );
    } catch (error) {
      if (mounted) await handleLimitOrMessage(context, error);
    }
  }

  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportScreen(siteId: widget.siteId),
      ),
    );
  }

  Future<void> _shareReport(String reportId, Rect? origin) async {
    final controller = AppScope.of(context);
    SavedReport? report;
    for (final item in controller.reports) {
      if (item.id == reportId) {
        report = item;
        break;
      }
    }
    if (report == null) return;
    try {
      await sharePdf(
        path: controller.reportPath(report),
        fileName: controller.shareFileName(report),
        subject: '写真日報 ${report.siteName}',
        origin: origin,
      );
    } catch (_) {
      if (mounted) {
        await showSnack(context, '共有シートを開けませんでした。');
      }
    }
  }

  Future<void> _deleteReport(String reportId) async {
    final ok = await confirmAction(
      context,
      title: 'この日報を削除しますか？',
      body: 'PDFもこのiPhoneから消えます。無料プランでは、削除すると作成枠が1件戻ります。',
      confirmLabel: '削除',
    );
    if (!ok || !mounted) return;
    await AppScope.of(context).deleteReport(reportId);
  }
}

class _PhotoPane extends StatelessWidget {
  const _PhotoPane({required this.empty, required this.children});

  final bool empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'この現場の写真はまだありません。\nカメラかライブラリから追加できます。メモは空でも大丈夫です。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ),
      );
    }
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.72,
      children: children,
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.path,
    required this.time,
    required this.memo,
    required this.onTap,
  });

  final String path;
  final String time;
  final String memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover, cacheWidth: 480)
                  : const ColoredBox(
                      color: AppColors.paper,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.muted,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    memo.isEmpty ? 'メモなし' : memo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: memo.isEmpty ? AppColors.muted : AppColors.ink,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPane extends StatelessWidget {
  const _ReportPane({required this.reports});

  final List<Widget> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'まだ日報はありません。\n写真を選んでPDFにすると、ここに残ります。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => reports[index],
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.title,
    required this.detail,
    required this.onShare,
    required this.onDelete,
  });

  final String title;
  final String detail;
  final void Function(Rect? origin) onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, color: AppColors.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '共有',
              onPressed: () => onShare(shareOriginOf(context)),
              icon: const Icon(Icons.ios_share),
            ),
            IconButton(
              tooltip: '削除',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
