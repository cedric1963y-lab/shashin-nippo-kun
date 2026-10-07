import 'package:flutter/material.dart';

import '../plan/limits.dart';

enum LegalTopic { terms, privacy }

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.topic, super.key});

  final LegalTopic topic;

  @override
  Widget build(BuildContext context) {
    final title = topic == LegalTopic.terms ? '利用規約' : 'プライバシー';
    final body = topic == LegalTopic.terms ? _terms : _privacy;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(body, style: const TextStyle(fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }
}

const _terms =
    '''
写真日報くんのプレミアムは、自動更新のサブスクリプションです。

・月額: ${PlanLimits.monthlyPriceLabel}（1か月）
・年額: ${PlanLimits.yearlyPriceLabel}（1年）

表示価格は日本の想定価格です。購入画面に出る金額が、請求される金額です。

支払いは購入を確定した時点で Apple ID に請求されます。期間が終わる24時間以上前に解約しない場合、同じ期間・同じ価格で自動更新されます。更新料は、期間が終わる前の24時間以内に請求されます。

契約中は、日報PDFと写真の件数上限が外れます。解約したあとも、その期間の終わりまでは使えます。期間が終わると、新しく作れる日報は${PlanLimits.freeReportLimit}件、保存できる写真は${PlanLimits.freePhotoLimit}枚に戻ります。それまでに保存した現場、写真、日報は消えません。

管理と解約は、iPhone の「設定」> Apple ID >「サブスクリプション」から行えます。返金は Apple の基準に従います。

無料プランでも、作った日報の再共有は削除するまで無料です。
''';

const _privacy = '''
写真日報くんは、現場の写真と日報をこの iPhone の中だけに保存します。

・アカウントはありません
・運営のサーバーへ写真、日報、購入情報を送りません
・広告 SDK は入れていません

購入の確認は Apple の App Store（StoreKit）が行います。契約の有効期限はこのアプリ内に控え、期限が切れたあとも写真と日報は残します。

iPhone のバックアップをオンにしている場合、Apple のバックアップに写真と日報が含まれることがあります。アプリを削除すると、この中の写真と日報も消えます。

カメラと写真ライブラリは、日報に載せる写真を選ぶためだけに使います。ライブラリへ写真を書き戻すことはありません。
''';
