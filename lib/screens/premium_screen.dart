import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../format.dart';
import '../plan/limits.dart';
import '../state/app_controller.dart';
import '../theme.dart';
import 'legal_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  AppController? _controller;
  var _wasPremium = false;
  var _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    if (!identical(_controller, controller)) {
      _controller?.removeListener(_onChange);
      _controller = controller;
      _wasPremium = controller.premium;
      controller.addListener(_onChange);
      _listening = true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).refreshProduct();
    });
  }

  void _onChange() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    if (!_wasPremium && controller.premium) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('プレミアムが有効になりました。期限までは上限が外れています。')),
        );
    }
    _wasPremium = controller.premium;
  }

  @override
  void dispose() {
    if (_listening) _controller?.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final pending = controller.purchasePhase == PurchasePhase.pending;
    final expires = controller.entitlement.expiresAt;
    final overLimit =
        !controller.premium &&
        (controller.photos.length >= PlanLimits.freePhotoLimit ||
            controller.reports.length >= PlanLimits.freeReportLimit);

    return Scaffold(
      appBar: AppBar(title: const Text('プレミアム')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const Text(
            '現場の数だけ、日報を残す。',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '月額 ¥100 が基本です。年額は ¥1,200 で、月あたりにすると同じ金額です。',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          if (controller.premium && expires != null) ...[
            const SizedBox(height: 16),
            _NoteCard(
              title: 'プレミアムは有効です',
              body:
                  '${PlanLimits.planName(controller.entitlement.productId)} · ${formatJapaneseDate(expires)}まで、日報も写真も無制限です。',
            ),
          ],
          const SizedBox(height: 18),
          _PlanCard(
            name: '月額',
            price: controller.priceFor(PlanLimits.monthlyProductId),
            period: '1か月ごとに自動更新',
            emphasized: true,
            child: FilledButton(
              key: const Key('buy-monthly'),
              onPressed:
                  pending || _current(controller, PlanLimits.monthlyProductId)
                  ? null
                  : () => controller.buyPlan(PlanLimits.monthlyProductId),
              child: pending
                  ? const _PendingMark()
                  : Text(
                      _current(controller, PlanLimits.monthlyProductId)
                          ? '月額を契約中'
                          : '月額ではじめる',
                    ),
            ),
          ),
          const SizedBox(height: 10),
          _PlanCard(
            name: '年額',
            price: controller.priceFor(PlanLimits.yearlyProductId),
            period: '1年ごとに自動更新',
            emphasized: false,
            child: OutlinedButton(
              key: const Key('buy-yearly'),
              onPressed:
                  pending || _current(controller, PlanLimits.yearlyProductId)
                  ? null
                  : () => controller.buyPlan(PlanLimits.yearlyProductId),
              child: Text(
                _current(controller, PlanLimits.yearlyProductId)
                    ? '年額を契約中'
                    : '年額ではじめる',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '支払いは購入の確定時に Apple ID へ請求されます。期間終了の24時間以上前に解約しない場合、同じ期間で自動更新され、終了前の24時間以内に更新料が請求されます。解約は「設定」> Apple ID >「サブスクリプション」です。',
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          const _Benefit(text: '契約中は日報PDFを何件でも作成'),
          const _Benefit(text: '契約中は写真を何枚でも保存'),
          const _Benefit(text: '期限が切れても、保存済みの写真と日報は残る'),
          const SizedBox(height: 8),
          const _NoteCard(
            title: '無料プラン',
            body: '日報は3件、写真は20枚までです。作った日報の再共有は、削除するまで何度でも無料です。日報や写真を削除すると、その分だけ枠が戻ります。',
          ),
          const SizedBox(height: 10),
          const _NoteCard(
            title: '広告はありません',
            body: '無料でもプレミアムでも、広告は出しません。現場写真には住宅や人が写ることがあるため、広告SDKは入れていません。',
          ),
          if (overLimit) ...[
            const SizedBox(height: 10),
            const _NoteCard(
              title: '保存した分はそのままです',
              body: '上限を超えて保存している写真や日報は消えません。新しく追加するには、枠が空くまで削除するか、プレミアムを再開してください。',
            ),
          ],
          if (controller.purchaseError != null) ...[
            const SizedBox(height: 16),
            Text(
              controller.purchaseError!,
              style: const TextStyle(color: AppColors.danger, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: pending ? null : controller.restorePremium,
            child: const Text('購入を復元'),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _openLegal(context, LegalTopic.terms),
                child: const Text('利用規約'),
              ),
              TextButton(
                onPressed: () => _openLegal(context, LegalTopic.privacy),
                child: const Text('プライバシー'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _current(AppController controller, String productId) {
    return controller.premium && controller.entitlement.productId == productId;
  }

  void _openLegal(BuildContext context, LegalTopic topic) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => LegalScreen(topic: topic)));
  }
}

class _PendingMark extends StatelessWidget {
  const _PendingMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.emphasized,
    required this.child,
  });

  final String name;
  final String price;
  final String period;
  final bool emphasized;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFFFF1E8) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emphasized ? AppColors.orange : AppColors.line,
          width: emphasized ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.slate,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(period, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(height: 1.45, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
