import 'dart:io';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../format.dart';
import '../plan/limits.dart';
import '../screens/premium_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/site_screen.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final sites = controller.sitesByRecent;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [
          IconButton(
            tooltip: '設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: sites.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-site'),
              onPressed: () => _addSite(context),
              icon: const Icon(Icons.add),
              label: const Text('現場を追加'),
            ),
      body: Column(
        children: [
          UsageBar(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
              );
            },
          ),
          Expanded(
            child: sites.isEmpty
                ? const _EmptySites()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: sites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final site = sites[index];
                      final photos = controller.photoCountFor(site.id);
                      final reports = controller.reportCountFor(site.id);
                      final latest = controller.photosFor(site.id);
                      return _SiteCard(
                        name: site.name,
                        note: site.note,
                        photos: photos,
                        reports: reports,
                        when: formatShortDate(controller.lastActivity(site)),
                        thumbnailPath: latest.isEmpty
                            ? null
                            : controller.photoPath(latest.first),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SiteScreen(siteId: site.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSite(BuildContext context) async {
    final draft = await showSiteDialog(context);
    if (draft == null || !context.mounted) return;
    try {
      await AppScope.of(context).addSite(name: draft.name, note: draft.note);
    } catch (error) {
      if (context.mounted) await handleLimitOrMessage(context, error);
    }
  }
}

class _EmptySites extends StatelessWidget {
  const _EmptySites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.slate,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '現場がまだありません',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '現場名を登録して、写真と短いメモを残すと、その日の日報PDFが作れます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                height: 1.5,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '写真はこのiPhoneの中だけに残ります。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const Key('add-site'),
              onPressed: () async {
                final draft = await showSiteDialog(context);
                if (draft == null || !context.mounted) return;
                try {
                  await AppScope.of(context)
                      .addSite(name: draft.name, note: draft.note);
                } catch (error) {
                  if (context.mounted) {
                    await handleLimitOrMessage(context, error);
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('現場を追加'),
            ),
          ],
        ),
      ),
    );
  }
}

class UsageBar extends StatelessWidget {
  const UsageBar({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final expires = controller.entitlement.expiresAt;
    final title = controller.premium
        ? 'プレミアム · ${PlanLimits.planName(controller.entitlement.productId)}'
        : '無料プラン';
    final detail = controller.premium && expires != null
        ? '${formatJapaneseDate(expires)}まで無制限'
        : '日報 ${controller.reports.length}/${PlanLimits.freeReportLimit} · 写真 ${controller.photos.length}/${PlanLimits.freePhotoLimit}';
    final tight =
        !controller.premium &&
        (controller.reports.length >= PlanLimits.freeReportLimit ||
            controller.photos.length >= PlanLimits.freePhotoLimit);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        color: tight ? const Color(0xFFFFF1E8) : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tight ? AppColors.orange : AppColors.line),
        ),
        child: InkWell(
          key: const Key('usage-bar'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  controller.premium
                      ? Icons.verified_outlined
                      : Icons.inventory_2_outlined,
                  color: controller.premium
                      ? AppColors.orange
                      : AppColors.slate,
                ),
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
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.name,
    required this.note,
    required this.photos,
    required this.reports,
    required this.when,
    required this.thumbnailPath,
    required this.onTap,
  });

  final String name;
  final String note;
  final int photos;
  final int reports;
  final String when;
  final String? thumbnailPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumb(path: thumbnailPath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '写真 $photos · 日報 $reports · $when',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    final ready = file != null && file.existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: ready
            ? Image.file(file, fit: BoxFit.cover, cacheWidth: 200)
            : const ColoredBox(
                color: AppColors.slate,
                child: Icon(Icons.apartment_outlined, color: Colors.white),
              ),
      ),
    );
  }
}
