# RecaLoop Cafeloop Foundation Audit

作業方針: 既存の RecaLoop を置き換えず、画面構成と将来機能の入口を段階的に追加する。Cafeloop は参考資料であり、実行時依存にはしない。

## 変更前の主な画面・ルート

- `/dashboard?view=home`: ホーム
- `/dashboard?view=reviews`: 復習
- `/dashboard?view=decks`: デッキ
- `/dashboard?view=calendar`: カレンダー
- `/dashboard?view=students`: 先生向け生徒管理
- `/dashboard?view=assignments`: 生徒向け課題
- `/dashboard?view=titles`: 称号
- `/dashboard?view=settings`: 設定
- `/deck-builder`: ローカル `.recaloop` 作成
- `/library`: 既存の公開ライブラリ
- `/rankings`: 既存ランキング
- `/share/...`: 既存共有リンク
- `/admin/submissions`: 既存管理画面

## 変更後の基本ナビゲーション

スマートフォン下部ナビは 5 項目へ整理。

- ホーム
- 学習
- 教材
- 進捗
- カフェ

プロフィール、設定、お知らせ、先生/生徒向け画面は上部またはサイドの補助導線に移動。

## 移動・整理した既存機能

- 復習: 学習画面とホームカードから入れる。既存の復習画面は維持。
- デッキ: 教材画面へ統合。既存のデッキ詳細、CSV、`.recaloop` は維持。
- カレンダー: 進捗画面のショートカットから入れる。既存画面は維持。
- 称号: 進捗画面とホームの称号導線から入れる。既存画面は維持。
- 課題/生徒: role に応じてヘッダー・サイドの補助導線として維持。

## 利用可能な機能

- 問題を解く
- 復習する
- 予定を始める
- マイ教材
- 教材作成
- インポート
- カレンダー
- 称号

## 開発中の機能

- 勉強時間の手動記録
- デジタルタイマー
- ポモドーロ
- 目標
- 学習時間集計
- 模試・テスト結果
- 教材別・教科別集計
- 教材の教科カテゴリ
- 教材画像

## Coming Soon / Future

- アナログタイマー
- カフェ集中
- リスニングプレーヤー
- 内蔵教材
- お気に入り
- 教材を探す
- 詳細分析
- AI分析
- マイカフェ
- お客さん
- 模様替え
- ショップ
- カフェランキング
- 学習パートナー

## ネイティブ版予定

- 触覚フィードバック
- プッシュ通知
- ウィジェット
- ライブアクティビティ
- スクリーンタイム連携

## EXP 調査

現在の EXP は主に `review_target` RPC で発生している。

- 教材 item 評価: `+5`
- カード評価: `+3`
- 復習完了: `+5`
- 初回デッキ完走: `+50`
- 連続学習日数ボーナス: `+10`

注意点:

- 評価保存と復習完了が同じ操作内で重なるため、条件次第で複数理由の EXP が同時に入る。
- teacher viewer mode の `review_target_for_student` は通常ユーザー用と挙動が異なる箇所があるため、EXP 統合前に再調査が必要。
- 勉強時間の手動記録で EXP を付与する場合、既存の問題評価 EXP と二重加算にならない設計が必要。
- 今回は既存 EXP 計算を変更していない。

## 追加マイグレーション

`supabase/migrations/0034_cafeloop_foundation.sql`

追加・拡張:

- `subject_categories`
- `goals`
- `tests`
- `test_subject_results`
- `manual_study_logs`
- `material_decks.subject_category_id`
- `material_decks.cover_media_id`
- `word_lists.subject_category_id`
- `word_lists.cover_media_id`
- `study_sessions` の insert/update policy 補強

RLS:

- 新規テーブルはすべて RLS 有効。
- 原則 `user_id = auth.uid()` で自分のデータだけ読み書き。
- `test_subject_results` の insert は親 `tests` の所有者も確認。

## Supabaseで実行が必要なSQL

開発用 Supabase にのみ `0034_cafeloop_foundation.sql` を適用する。本番 Supabase には未適用。

## 次に実装すべき機能

1. 勉強時間の手動記録 UI と `manual_study_logs` 保存
2. デジタルタイマーとポモドーロ
3. 目標 CRUD
4. 模試・テスト結果の基本登録
5. 教材作成の簡略化 UI と教科カテゴリ選択
6. EXP 統合設計の確定
