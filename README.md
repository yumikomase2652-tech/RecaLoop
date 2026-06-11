# RecaLoop MVP

受験生向けの教材進捗・復習・暗記カード・先生生徒連携アプリです。

## 起動

```bash
npm install
cp .env.example .env.local
npm run dev
```

環境変数なしでは、サンプルデータ入りのデモUIとして動作します。

## Supabase セットアップ

1. Supabaseで新規プロジェクトを作成する
2. SQL Editorで `supabase/migrations/0001_recaloop.sql` を実行する
3. `.env.local` にProject URLとanon keyを設定する
4. Authentication > URL ConfigurationでサイトURLを設定する

DB関数 `add_study_log`、`complete_review`、`review_flashcard` が復習予定作成とLoopCoin付与を原子的に処理します。RLSにより、本人と連携済みの先生だけが必要な学習データを参照できます。

## 主な画面

- `/` デモ兼ダッシュボード
- `/login` メール認証
- `/setup` 初期設定・複数ロール選択

暗記カードはユーザーの自作内容を前提とし、教材全文の転載を促さない注意文を表示しています。
