# 提出チェックリスト

2026-10-07 時点の切り分けです。App Store Connect へのログイン、アプリ登録、商品の作成、ビルドのアップロードはしていません。

## リポジトリで揃っている

- 表示名: 写真日報くん（`CFBundleDisplayName` / `CFBundleName`）
- バージョン: 1.0.0（ビルド 1）
- Bundle ID: `jp.shashinnippo.app`（Runner の3構成。テストターゲットは `jp.shashinnippo.app.RunnerTests`）
- 月額: `jp.shashinnippo.app.premium.monthly`（StoreKit 設定は1か月、表示価格 100）
- 年額: `jp.shashinnippo.app.premium.yearly`（1年、表示価格 1200）
- グループ名の目安: プレミアム。年額のランクが上
- 日本語のメタデータ下書き: `store/metadata-ja.md`
- カメラと写真ライブラリの使用目的（日本語）。ライブラリへの保存用の文言はない
- プライバシーマニフェスト: トラッキングなし、収集データなし。UserDefaults `CA92.1`、ファイル時刻 `C617.1`、ディスク容量 `E174.1`。アプリの Resources に入っている
- 輸出コンプライアンスのキー: `ITSAppUsesNonExemptEncryption = false`
- カテゴリのキー: `public.app-category.business`
- 広告 SDK なし（AdMob / `google_mobile_ads` / `GADApplicationIdentifier` / 追跡許可の文言なし）
- アプリアイコン一式と、PDF 用の Noto Sans JP（SIL OFL、`assets/fonts/OFL.txt`）
- スクリーンショット用スクリプト: `tool/capture_app_store_screenshots.sh`

## Mac が必要

- 署名チームを Xcode で選ぶ
- `flutter build ipa --release` か Product > Archive
- シミュレータで4枚の生スクリーンショット（`store/screenshots/README.md`）
- スクリーンショットは iPhone のシミュレータだけで撮る（iPad 向けビルドにはしていない）
- カメラは実機で確認する

## App Store Connect の画面が必要（未実施）

アカウント側の操作は、ここからは実行できません。次は手元で行う手順です。

1. Apple Developer で App ID `jp.shashinnippo.app` を自分のチームに登録する。登録済みかは未確認。
2. App Store Connect で新規 App を作る。名前は「写真日報くん」。バンドル ID は上記。SKU とプライマリ言語（日本語）はこのリポジトリでは決めていない。
3. サブスクリプショングループ「プレミアム」を作る。
4. 自動更新を2つ作る。製品 ID はコードと一字一句同じにする。
   - 月額: `jp.shashinnippo.app.premium.monthly`、1か月、日本 ¥100、表示名「プレミアム（月額）」、ランクは年額より下
   - 年額: `jp.shashinnippo.app.premium.yearly`、1年、日本 ¥1,200、表示名「プレミアム（年額）」、ランクは上
5. サブスクリプションのプロモーション用画像は付けない。画像ファイルは用意していない。
6. 有料アプリ契約、口座、税務情報はアカウント設定。このリポジトリでは未確認。
7. サポート URL とプライバシーポリシー URL を貼る。ページ本体は `docs/` にあり、アプリ内の文面と同じ。公開 URL はまだない。GitHub Pages（main の `/docs`）か Origin の静的ページで `docs/` を出すと、サポートは `/`、プライバシーは `/privacy.html`、利用規約は `/terms.html`。
8. `store/metadata-ja.md` の名前、サブタイトル、キーワード、概要、新機能を貼る。
9. スクリーンショットは Mac で撮った生 PNG を、Connect が求めるサイズの枠へ入れる。マーケティング用の合成はしない。
10. アーカイブしたビルドをそのバージョンに割り当て、審査メモの下書きを必要なら貼って提出する。

## プライバシー質問票の目安

開発者のサーバーへは何も送りません。質問票は未回答です。次は、その実装に沿った答えの目安です。

- データの収集: しない。写真、日報、メモ、購入情報は運営のサーバーへ出さない。
- トラッキング: しない。`NSPrivacyTracking` は false。追跡ドメインは空。ATT の許可文はない。
- 広告: 使わない。AdMob は依存関係にない。広告識別子は使わない。
- 「写真またはビデオ」: 収集しない、が実装に合う。カメラとライブラリは、日報に載せる写真をこの iPhone に保存するためだけ。ライブラリへ書き戻さない。
- 位置情報、連絡先、健康、閲覧履歴: 使わない。
- 識別子: アプリ独自のアカウントはない。
- 購入: Apple が処理する。レシート検証サーバーはない。購入データタイプを「開発者が収集」にはしない、が実装に合う。
- 診断や利用状況: Crashlytics などの SDK は入っていない。
- iPhone のバックアップをオンにしている場合、Apple のバックアップに写真が含まれることがある。これは開発者による収集ではない。

## コンテンツの権利

第三者の写真カタログも広告も、アプリ本体には入っていません。コンテンツ権利の質問で「第三者が権利を持つコンテンツを収録している」とは答えにくい構成です。スクリーンショットに使う現場写真だけは、公開してよいものに限ってください。埋め込みフォントは Noto Sans JP（SIL Open Font License、予約フォント名は Source）です。
