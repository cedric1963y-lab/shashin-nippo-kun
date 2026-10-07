import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../format.dart';
import '../plan/limits.dart';
import '../theme.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final expires = controller.entitlement.expiresAt;
    final plan = controller.premium && expires != null
        ? 'プレミアム（${PlanLimits.planName(controller.entitlement.productId)}）· ${formatJapaneseDate(expires)}まで'
        : '無料 · 日報 ${controller.reports.length}/${PlanLimits.freeReportLimit} · 写真 ${controller.photos.length}/${PlanLimits.freePhotoLimit}';

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.orange,
              ),
              title: const Text(
                'プラン',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(plan),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PremiumScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const _Card(
            child: _Block(
              title: '使い方',
              body: '1. 現場名を登録する\n2. 写真と短いメモを追加する\n3. 日報PDFを作って、LINEやメールで共有する',
            ),
          ),
          const SizedBox(height: 12),
          const _Card(
            child: _Block(
              title: '写真の扱い',
              body: '写真と日報はこのiPhoneの中だけに保存されます。アカウントは不要で、運営のサーバーには送りません。\n\niPhoneのバックアップをオンにしている場合、Appleのバックアップに含まれることがあります。アプリを削除すると、この中の写真と日報も消えます。',
            ),
          ),
          const SizedBox(height: 12),
          const _Card(
            child: _Block(
              title: 'バージョン',
              body: '${AppInfo.name} ${AppInfo.version}',
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(height: 1.5)),
      ],
    );
  }
}
