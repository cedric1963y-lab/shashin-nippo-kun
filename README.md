# 写真日報くん

一人親方・一人現場向けの iOS アプリです。現場の写真と短いメモを、その日の日報 PDF にして共有します。メモアプリや LINE の写真フォルダの代わりに使う、オフラインの道具です。

写真も日報も、この iPhone の中だけに保存します。会社アカウントもクラウド同期もありません。

## 無料とプレミアム

| | 無料 | プレミアム |
| --- | --- | --- |
| 日報 PDF | 3件まで | 無制限 |
| 写真 | 20枚まで（全現場合計） | 無制限 |
| 作った日報の再共有 | 削除するまで何度でも無料 | 同じ |
| 広告 | なし | なし |
| 価格 | ¥0 | **月額 ¥100**（基本）。年額 ¥1,200 も選べます |

- 日報や写真を削除すると、その分だけ無料枠が戻ります。
- 1件の日報に入れられる写真は 30 枚までです。これはプランではなく、PDF の大きさの上限です。
- プレミアムは自動更新サブスクリプションです。契約中だけ上限が外れます。
- 月額（基本）: `jp.shashinnippo.app.premium.monthly` · 1か月 · 日本 ¥100
- 年額: `jp.shashinnippo.app.premium.yearly` · 1年 · 日本 ¥1,200（月あたり ¥100 と同じです）
- 同じサブスクリプショングループ「プレミアム」に入れます。年額のランクを上にし、月額から年額への変更がアップグレードになるようにします。
- Bundle ID: `jp.shashinnippo.app`
- 期限が切れても、現場・写真・日報はこの iPhone に残ります。新しく追加できるのは無料の 3 件 / 20 枚までです。すでに上限を超えている場合は、削除して枠を空けるか、契約を再開します。作った日報の再共有は、削除するまで無料です。
- 機種変更や再インストールのあとは、「購入を復元」で同じ Apple ID の有効な契約を戻せます。期限の切れた契約は復元しても上限は外れません。
- アプリ内の金額は、StoreKit が返す表示価格を優先します。未取得のときは月額 ¥100、年額 ¥1,200 と出します。

確認は端末上の StoreKit が行います。レシート検証用のサーバーはありません。有効期限は StoreKit 2 の取引から読み、この iPhone に控えます。オフラインのあいだは、控えた期限までプレミアムのままです。ストアに聞けたときは、その回答で期限を更新します。

広告を入れない理由: 現場写真には住宅、顔、住所が写ることがあります。広告 SDK はトラッキングを伴うので、無料・プレミアムのどちらにも入れていません。無料は件数で区切り、契約中だけその上限を外します。

## できること

1. 現場名を登録する（メモに元請や住所を書ける）
2. カメラかライブラリから写真を追加する。短いメモと日時は任意で、あとから直せる
3. その日の写真を選んで日報 PDF を作る
4. iOS の共有シートから LINE やメールへ渡す
5. 作った日報は現場の「日報」から何度でも共有できる

電子黒板、会社の顧客管理、クラウド同期は対象外です。

## プライバシー

- カメラと写真ライブラリの使用目的は `ios/Runner/Info.plist` に日本語で書いてあります。
- 写真をライブラリへ保存しないので、追加用の許可文は入れていません。
- `ios/Runner/PrivacyInfo.xcprivacy` はトラッキングなし、収集データなしです。UserDefaults / ファイル時刻 / ディスク容量は、アプリと Flutter が端末内で使う範囲の理由コードだけです。
- 輸出コンプライアンスは `ITSAppUsesNonExemptEncryption = false` です。
- iPhone のバックアップをオンにしている場合、Apple のバックアップには含まれることがあります。アプリを削除すると、中の写真と日報も消えます。

App Store のプライバシー回答の目安: データ収集なし。トラッキングなし。

## 開発環境

- macOS
- Flutter stable 3.47 以降（このプロジェクトは 3.47.6 / Dart 3.13 で作成）
- Xcode 16 以降
- iOS 15 以降

このリポジトリは iOS だけです。CocoaPods ではなく Swift Package Manager を使います。`Podfile` はありません。

## ビルド

```bash
flutter pub get
open ios/Runner.xcworkspace
```

Xcode で Signing & Capabilities に自分の Team を設定します。

シミュレータではライブラリから写真を追加できます。カメラは実機で確認してください。

コマンドから実機へ入れる場合:

```bash
flutter run --release
```

アーカイブ:

1. Xcode で Runner スキームの Any iOS Device を選ぶ
2. Product > Archive
3. Organizer から Distribute App

または、署名が済んでいる Mac で:

```bash
flutter build ipa --release
```

## アプリ内課金の確認

`ios/Runner/Products.storekit` が月額と年額の自動更新です。`Runner` スキームの StoreKit Configuration は、このファイルを指しています。

Xcode の Run（`flutter run` ではなく Xcode から実行）で、購入シートをサンドボックスなしで試せます。実機の Sandbox アカウントでも確認できます。StoreKit テストとサンドボックスでは、1か月の更新が約5分、1年が約1時間に縮みます。

App Store Connect に作る商品（有料アプリ契約、口座、税務情報が必要です）:

- グループ名: プレミアム
- 月額: 自動更新、製品 ID `jp.shashinnippo.app.premium.monthly`、期間 1か月、日本 ¥100、表示名「プレミアム（月額）」、グループ内ランクは年額より下
- 年額: 自動更新、製品 ID `jp.shashinnippo.app.premium.yearly`、期間 1年、日本 ¥1,200、表示名「プレミアム（年額）」、グループ内ランクは上
- 以前の買い切り ID `jp.shashinnippo.app.premium` は使いません

購入画面には、期間、価格、自動更新、解約場所、「利用規約」「プライバシー」へのアプリ内リンクを出しています。App Store Connect のプライバシーポリシー URL には、アプリ内の「プライバシー」と同じ内容を掲載したページを指定してください。

審査メモの下書きは `store/metadata-ja.md` にあります。まだ送信していません。

## App Store への提出

文案は `store/metadata-ja.md`、揃っているものと未実施の切り分けは `store/submission-checklist.md` です。App Store Connect への登録、契約、アップロードはしていません。

### Mac でアーカイブ

署名の Team を Xcode で設定したあと:

```bash
flutter pub get
flutter build ipa --release
```

または Xcode で Any iOS Device を選び、Product > Archive、Organizer から Distribute App です。iOS 15 以降、iPhone のみです（`TARGETED_DEVICE_FAMILY = 1`）。iPad 用の画面は不要です。

### スクリーンショット

シミュレータの画面を、枠なしの PNG で4枚撮ります。スプラッシュは撮らず、購入画面の文言も変えません。アプリに PDF の専用プレビューはないので、3枚目は「日報を作る」か iOS の共有シートです。

```bash
tool/capture_app_store_screenshots.sh 01-site-list
```

操作は `store/screenshots/README.md` です。このスクリプトは macOS の起動中シミュレータだけを撮ります。

### App Store Connect で作るもの

次は Connect の画面で行う作業です。このリポジトリからは実行していません。

- 新規 App。バンドル ID `jp.shashinnippo.app`。名前は「写真日報くん」。SKU は未定。
- サブスクリプショングループ「プレミアム」。
- 月額 `jp.shashinnippo.app.premium.monthly`（1か月、日本 ¥100、表示名「プレミアム（月額）」）。
- 年額 `jp.shashinnippo.app.premium.yearly`（1年、日本 ¥1,200、表示名「プレミアム（年額）」、グループ内ランクは月額より上）。
- サブスクリプションのプロモーション用画像は付けない。ファイルは用意していません。
- 有料アプリ契約。サポート URL とプライバシーポリシー URL は、下の静的ページを公開してから貼る。
- メタデータの貼り付け、生スクリーンショット、アーカイブしたビルド。

### サポートとプライバシーのページ

`docs/index.html`（サポート）、`docs/privacy.html`（プライバシーポリシー）、`docs/terms.html`（利用規約）は、アプリ内の「プライバシー」「利用規約」と同じ内容です。広告もトラッキングもありません。公開 URL はまだありません。GitHub にミラーして Pages のソースを main の `/docs` にする（または Origin の静的ページで `docs/` を出す）と、サポートは `/`、プライバシーは `/privacy.html`、利用規約は `/terms.html` です。

### プライバシー質問票の目安

開発者のサーバーへは送っていません。質問票は未回答です。

- データ収集なし。トラッキングなし。広告なし（AdMob も追跡許可の文言もありません）。
- 写真は端末内だけなので、「写真またはビデオ」を収集する、とは答えないのが実装に合います。
- 位置情報、連絡先、アカウント用の識別子、診断 SDK はありません。
- 購入は Apple が処理します。レシート検証サーバーはありません。
- コンテンツの権利: 第三者の写真カタログや広告は入っていません。ストア用の画面写真は、公開してよいものだけ使ってください。

## テスト

macOS でも Linux でも、シミュレータなしでロジックは確認できます。

```bash
flutter analyze
flutter test
```

## アイコンと書体

アプリアイコンは、日報の紙、現場写真、ヘルメットの図です。木材の立方体ではありません。元画像は `assets/icon/app_icon.png` で、各サイズは `ios/Runner/Assets.xcassets/AppIcon.appiconset` に入っています。

日報 PDF の日本語は Noto Sans JP Regular（SIL Open Font License）です。ライセンスは `assets/fonts/OFL.txt` です。Reserved Font Name は Source なので、フォント名は変えていません。PDF には使った文字だけを埋め込みます。

## 構成

- `lib/state/app_controller.dart` — 現場・写真・日報・契約状態
- `lib/plan/entitlement.dart` — 期限付きのプレミアム
- `lib/data/repository.dart` — 端末内の JSON とファイル
- `lib/services/pdf_report.dart` — A4 の日報
- `lib/services/store_purchase_gateway.dart` — StoreKit
- `ios/Runner/Info.plist` — 日本語の利用目的
- `ios/Runner/PrivacyInfo.xcprivacy` — プライバシーマニフェスト
