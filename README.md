# RecaLoop

**教材の章・節・問題番号とフラッシュカードを整理し、4段階の自己評価で次の復習につなげる学習Webアプリです。**

React / TypeScript / Next.jsとSupabaseで個人開発しているプロトタイプです。復習予定・学習履歴・課題を同じ教材構造につなげることを中心にしています。

## 解決したい課題

紙の教材で勉強した範囲と、デジタルのカード学習の履歴を別々に管理すると、何をいつ復習するかが分かりにくくなります。RecaLoopでは教材の構造や問題番号だけでも登録でき、自己評価・復習予定・学習計画を関連付けられる構成にしています。

## 実装している機能

| 領域 | 内容 |
| --- | --- |
| 教材・カード | 章・節・問題番号の階層、表裏のカード、メモ、CSVのプレビューとインポート |
| 復習 | again / hard / good / easyの4段階評価、日付単位の復習予定、チェック、評価履歴、1問ずつの学習 |
| 学習計画 | 選択した項目を期間へ配分、カレンダー表示、予定日の変更 |
| 教師・生徒 | 招待コードによる連携、課題配布、進捗表示、連携生徒の画面確認 |
| データ交換 | `.recaloop`ファイルで教材と画像・音声を読み込み／書き出し |
| 継続の可視化 | 学習履歴、EXP・レベル・称号、ヒートマップ |
| 認証 | Supabase Auth、メール確認、パスワード再設定 |

ここでの「実装」はコード上の存在を指します。認証・DB接続・教師生徒間の権限制御を含む全導線の動作検証が完了したという意味ではありません。

## 技術的な見どころ

- **教材構造と学習履歴の分離**：階層や問題番号を手掛かりに教材を扱い、再インポート時に既存の履歴を維持する処理を実装しています。
- **データ操作の集約**：Supabaseの呼び出しを`lib/recaloop-data.ts`に、CSV解析を`lib/csv.ts`に分けています。
- **教材パッケージ**：`lib/recaloop-package.ts`が`.recaloop`形式を扱います。教材データとメディアをまとめ、学習者の評価・履歴は書き出し対象から分けています。
- **メディアの端末内保存**：画像・音声の実体はIndexedDB、参照と学習データはSupabaseで扱います。
- **DB側の権限制御**：SQL migrationにRLSポリシーとRPCを定義しています。教師と連携生徒の閲覧は個人所有とは別の権限を持つため、公開サービスでの利用には権限ごとの動作確認が必要です。

## 現在の範囲と制約

- 復習は段階と日数間隔に基づく簡易スケジューリングです。AnkiやFSRSの完全互換ではなく、分単位の学習ステップも完成していません。
- AI問題生成、4択問題の自動生成、一般公開ライブラリ、APKG互換、課金は現行の完成機能として提供していません。
- PWAのmanifestと最小Service Workerはありますが、Service Workerにオフラインキャッシュはありません。
- DB未設定時に体験用データへ切り替えるモードはありません。初回起動には自分のSupabase環境が必要です。
- IndexedDBのメディアは端末内に保存されるため、別端末へ自動同期されません。
- UI改修中の`dev`ブランチと`main`では状態が異なります。このREADMEの起動・検証記録は`main`が対象です。

## 技術スタック

Next.js / React / TypeScript / Tailwind CSS / Supabase Auth・PostgreSQL / IndexedDB

## ローカル起動

検証環境：Node.js 24 / npm 11。

```bash
git clone https://github.com/yumikomase2652-tech/RecaLoop.git
cd RecaLoop
npm ci
cp .env.example .env.local
```

自分のSupabaseプロジェクトを用意し、`.env.local`に公開URLと公開用anon keyを設定します。**service_role keyやDBパスワードをNEXT_PUBLIC_変数に設定しないでください。** `.env.local`はGitに追加しません。

新規の開発用DBへ、`supabase/migrations/`のSQLを`0001`から`0032`まで番号順に適用してください。READMEの古い一覧だけでなく、ディレクトリ内の全ファイルが対象です。既存の本番DBへ動作確認目的で適用したり、リセットしたりしないでください。

Supabase AuthenticationのRedirect URLには、ローカル用に`http://localhost:3000/auth/callback`と`http://localhost:3000/auth/update-password`を登録します。

```bash
npm run dev
```

`http://localhost:3000`を開き、自分で用意したテストアカウントと自作教材を使って確認してください。

## 構成

```text
app/                     画面・認証コールバック
components/              学習画面・教材・教師生徒のUI
lib/recaloop-data.ts      Supabaseデータ操作
lib/csv.ts               CSV解析
lib/fsrs.ts              日付単位の簡易復習計算
lib/recaloop-package.ts   教材パッケージ入出力
lib/local-media.ts        画像・音声の端末内保存
supabase/migrations/     スキーマ・RLS・RPC
```

## 検証

2026-11-05、実データとSupabase環境変数を入れない調査用コピーで以下が成功しました。

```bash
npm run lint
npx --no-install tsc --noEmit
npm run build
```

認証メールの送信、DB migrationの適用、ユーザー間の権限制御、公開デモとモバイル実機の一連の動作は、この検証には含みません。

## データと教材の扱い

サンプルには自作の問題や架空の記録を使ってください。教材名・章・節・問題番号の整理と、問題文・解答・画像・音声を再配布することは別です。権利のない教材本文や他人の学習記録は公開しないでください。

## 関連プロジェクト・詳細

- TutorLoop：端末内保存を使う以前の試作。RecaLoop本体とは別の実装です。
- recaloop-deck-tools：教材構造の変換・検証を検討した計画用リポジトリ。現在、独立したツールの実装はありません。
- [開発メモ・形式詳細・手動テスト項目](docs/development-notes.md)

## ライセンス

現時点でオープンソースライセンスは設定していません。
