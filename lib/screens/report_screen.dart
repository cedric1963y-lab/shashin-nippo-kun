import 'dart:io';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../errors.dart';
import '../format.dart';
import '../models/records.dart';
import '../plan/limits.dart';
import '../services/share_pdf.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({required this.siteId, super.key});

  final String siteId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _summary = TextEditingController();
  final Set<String> _selected = {};
  DateTime? _day;
  bool _includeOthers = false;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final photos = AppScope.of(context).photosFor(widget.siteId);
    if (photos.isEmpty) return;
    final today = DateTime.now();
    final hasToday = photos.any((photo) => isSameDay(photo.takenAt, today));
    _day = hasToday ? today : photos.first.takenAt;
    for (final photo in photos) {
      if (isSameDay(photo.takenAt, _day!)) _selected.add(photo.id);
    }
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final site = controller.siteById(widget.siteId);
    final photos = controller.photosFor(widget.siteId);
    if (site == null) {
      return const Scaffold(body: Center(child: Text('この現場は削除されました。')));
    }

    final days = <DateTime>[];
    for (final photo in photos) {
      if (!days.any((day) => isSameDay(day, photo.takenAt))) {
        days.add(photo.takenAt);
      }
    }
    final visible = _includeOthers || _day == null
        ? photos
        : photos.where((photo) => isSameDay(photo.takenAt, _day!)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('日報を作る')),
      body: photos.isEmpty
          ? const Center(child: Text('先に写真を追加してください。'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  site.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'その日の写真が選ばれています。PDFでは時刻の早い順に並びます。',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final selected = _day != null && isSameDay(day, _day!);
                      final label = isSameDay(day, DateTime.now())
                          ? '今日'
                          : formatShortDate(day);
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => _selectDay(day, photos),
                        selectedColor: AppColors.orange,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _summary,
                  maxLength: 120,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '今日のひとこと（任意）',
                    hintText: '例）外壁下地まで完了、明日塗装',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ほかの日の写真も表示'),
                  value: _includeOthers,
                  activeThumbColor: AppColors.orange,
                  onChanged: (value) {
                    setState(() {
                      _includeOthers = value;
                      if (!value && _day != null) {
                        _selected.removeWhere((id) {
                          final photo = controller.photoById(id);
                          return photo == null ||
                              !isSameDay(photo.takenAt, _day!);
                        });
                      }
                    });
                  },
                ),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'この日の写真はありません。',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  for (final photo in visible)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _selected.contains(photo.id),
                      activeColor: AppColors.orange,
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            _selected.add(photo.id);
                          } else {
                            _selected.remove(photo.id);
                          }
                        });
                      },
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(controller.photoPath(photo)),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          cacheWidth: 160,
                          errorBuilder: (context, error, stack) =>
                              const SizedBox(
                                width: 52,
                                height: 52,
                                child: ColoredBox(
                                  color: AppColors.paper,
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                        ),
                      ),
                      title: Text(formatTime(photo.takenAt)),
                      subtitle: Text(
                        photo.memo.isEmpty ? 'メモなし' : photo.memo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
            ),
      bottomNavigationBar: Material(
        color: AppColors.card,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '選択中 ${_selected.length}枚',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (_selected.length > PlanLimits.maxPhotosPerReport)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '1件の日報は30枚までです。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: photos.isEmpty ? null : () => _create(context),
                  child: const Text('PDFを作成して共有'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectDay(DateTime day, List<SitePhoto> photos) {
    setState(() {
      _day = day;
      _includeOthers = false;
      _selected
        ..clear()
        ..addAll([
          for (final photo in photos)
            if (isSameDay(photo.takenAt, day)) photo.id,
        ]);
    });
  }

  Future<void> _create(BuildContext context) async {
    final controller = AppScope.of(context);
    if (!controller.canCreateReport) {
      await showLimitDialog(context, LimitKind.reports);
      return;
    }
    if (_selected.isEmpty) {
      await showSnack(context, '写真を1枚以上選んでください。');
      return;
    }
    if (_selected.length > PlanLimits.maxPhotosPerReport) {
      await showLimitDialog(context, LimitKind.photosPerReport);
      return;
    }
    final origin = shareOriginOf(context);
    try {
      final report = await runBlocking(context, 'PDFを作成しています', () {
        return controller.createReport(
          siteId: widget.siteId,
          reportDate: _day ?? DateTime.now(),
          summary: _summary.text,
          photoIds: _selected.toList(),
        );
      });
      if (!context.mounted) return;
      try {
        await sharePdf(
          path: controller.reportPath(report),
          fileName: controller.shareFileName(report),
          subject:
              '写真日報 ${report.siteName} ${formatJapaneseDate(report.reportDate)}',
          origin: origin,
        );
      } catch (_) {
        if (context.mounted) {
          await showSnack(context, '日報は保存しました。共有は日報一覧からもう一度できます。');
        }
      }
      if (context.mounted) Navigator.pop(context);
    } on LimitReached catch (error) {
      if (context.mounted) {
        await showLimitDialog(context, error.kind);
      }
    } on InvalidInput catch (error) {
      if (context.mounted) {
        await showSnack(context, error.message);
      }
    } catch (_) {
      if (context.mounted) {
        await showSnack(context, '日報を作成できませんでした。空き容量を確認してください。');
      }
    }
  }
}
