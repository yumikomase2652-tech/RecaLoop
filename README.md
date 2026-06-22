# RecaLoop 個人学習MVP

教材の問題番号と自作暗記カードを登録し、4段階評価で復習日を管理する個人用Webアプリです。

## 今回の範囲

- Supabase Authによるメール認証
- メール確認コールバックとパスワード再設定
- 教材デッキと無限階層の章・節・問題番号
- 柔軟な教材CSVインポートとプレビュー
- 暗記カード、自作カード、CSVインポート
- `again / hard / good / easy`評価
- チェック、復習予定、評価履歴
- 一覧評価と1問ずつの学習モード
- 教材デッキ・暗記カードの公開リンク共有と独立コピー
- PWA manifestとアプリアイコン

先生生徒機能、課題配布、高度なSNS、APKG、R2、コインUIは含みません。

## 起動

```bash
npm install
cp .env.example .env.local
npm run dev
```

Supabase未設定時は `/dashboard` がデモデータで動きます。

## Supabase

新しいSupabaseプロジェクトのSQL Editorで次を実行します。

```text
supabase/migrations/0001_recaloop.sql
```

既存の個人用MVPデータベースには、続けて次を実行してください。

```text
supabase/migrations/0002_add_card_id.sql
supabase/migrations/0003_sharing.sql
```

今回は旧版からの大規模な作り直しです。旧版の先生生徒テーブルが存在するDBへ差分適用するSQLではありません。開発中の旧DBはリセットするか、新規プロジェクトを使用してください。

`.env.local`:

```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

全学習テーブルでRLSを有効にし、ログインユーザー本人が所有するデータだけを操作できます。評価保存は`review_target` RPCでstate更新とattempt履歴作成を一度に行います。

共有を有効にしたデッキだけは、共有URLから構造・問題番号・カード内容を読み取れます。評価state、attempt履歴、チェック、プロフィールは公開されません。「自分のアカウントに追加」は認証済みユーザー用RPCで新しい所有データとして複製します。

Supabase AuthenticationのURL Configurationには、ローカル開発時は`http://localhost:3000/auth/callback`、本番では本番ドメインの`/auth/callback`をRedirect URLとして登録してください。

## CSV

教材CSVは左から右を大階層から小階層として解釈し、最後の非空セルを問題itemにします。

```csv
第1章 物質の構成,第1回 原子,エクササイズ,問1
第1章 物質の構成,第1回 原子,エクササイズ,問2
```

暗記カードCSVは`card_id,front,back,memo`形式です。`card_id`と`memo`は省略できます。

```csv
card_id,front,back,memo
001,apple,りんご,名詞
002,run,走る,動詞
```

どちらも保存前にitem数、階層、重複候補を確認できます。

## 復習間隔

復習計算は`lib/fsrs.ts`の`calculateNextReview`に集約しています。

- `again`: 今日
- `hard`: 1日後
- `good`: 3日後
- `easy`: 7日後

## 著作権への配慮

教材デッキでは教材名、章・節、問題番号、自分用の短いメモだけを扱います。教材本文、問題文、解答全文を入力するUIはありません。暗記カードはユーザー自身が作成した`front / back / memo`を保存します。

## PWA・ネイティブ化

`app/manifest.ts`と`public/icon.svg`を用意し、standalone表示に対応しています。画面とSupabaseアクセスはブラウザ標準APIだけに依存しているため、将来は同じWebビルドをCapacitorでラップできます。Expoへ移行する場合も、`lib/recaloop-data.ts`のデータ操作境界を再利用しやすい構成です。

## 検証

```bash
npm run lint
npm run build
```
