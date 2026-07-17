# RecaLoop 現状画面設計書

作成日：2026-07-17  
調査対象：`app/`、`components/`、`lib/` 配下のルート・画面コンポーネント・主要UI・データ取得関数  
注意：この文書はコード上で確認できた事実を中心に整理しています。推測が必要な箇所は「確認できない」または「コード上は判別不能」と明記しています。

## 1. アプリ全体の構造

- 使用しているルーティング方式：Next.js App Router
  - `app/page.tsx`：ログイン前ランディング
  - `app/login/page.tsx`：ログイン・新規登録
  - `app/dashboard/page.tsx`：ログイン後のメインアプリ
  - `app/dashboard/layout.tsx`：Supabaseセッション確認と認証ガード
  - `app/admin/submissions/page.tsx`：管理者向け投稿申請画面
  - `app/deck-builder/page.tsx`：ログイン不要のローカルデッキ作成画面
  - `app/auth/callback/route.ts`：Supabase OAuth / email confirmation callback
  - `app/auth/update-password/page.tsx`：パスワード更新
  - `app/library/page.tsx`、`app/rankings/page.tsx`、`app/share/*`：現在は `/dashboard?view=decks` へリダイレクト
- 共通レイアウト：
  - `app/layout.tsx`
  - `app/globals.css`
  - `components/pwa-register.tsx`
- 共通ヘッダー：
  - メインアプリ内は `components/personal-app.tsx` の `AppTopBar` と `PageTitle`
  - `AppTopBar` は Home / Study / Progress / Cafe などで通知・先生/生徒導線・設定を表示
  - `PageTitle` は多くのサブ画面で戻るボタン・見出し・右側アクションを表示
- タブバー：
  - メインアプリ内は `BottomNav`（`components/personal-app.tsx`）
  - 5項目：`Home` / `Study` / `Calendar` / `Summary` / `Cafe`
  - アイコンは `components/nav-icons.tsx` の独自SVG
  - Studyタブは `study` だけでなく `materials` / `decks` / `reviews` / `assignments` もアクティブ扱い
  - Summaryタブは `progress` と `titles` を含む
  - Studyに復習件数、Calendarに予定件数、Cafeに在庫切れ想定の赤バッジ枠がある
- サイドバー：
  - 現在のメインアプリでは常設サイドバーは使われていない
  - `components/app-route-nav.tsx` にはPC用ミニリンクと下部ナビがあるが、現在の主要ルートからはほぼ使われていない
- Safe Areaの扱い：
  - `globals.css` と `.bottom-nav` 周辺で `env(safe-area-inset-bottom)` を使う設計
  - 画面全体のSafe Area設計はCSSに依存
- 認証状態による分岐：
  - Supabase環境変数がある場合、`app/dashboard/layout.tsx` で未ログインを `/login` にリダイレクト
  - `app/login/page.tsx` はログイン成功後 `/dashboard` へ遷移
  - `app/admin/submissions/page.tsx` はログイン済みかつ `profiles.is_admin` が必要
  - Supabase環境変数がない場合、ローカル確認用として一部ガードが緩くなる
- ユーザー種別による分岐：
  - `profiles.role`：`none` / `student` / `teacher`
  - teacher：`students` 画面への導線
  - student：`assignments` 画面への導線
  - none：個人利用メニュー
- 生徒・先生・Viewer Modeの違い：
  - `PersonalApp` が `viewerStudent` state と `localStorage("recaloop-viewer")` を持つ
  - Viewer Mode中は `viewerDataForStudent` で表示データを生徒対象に切り替える
  - 画面上部に `viewer-banner`：`○○さんの画面を表示中` / `戻る`
  - 保存処理は通常 `reviewTarget`、Viewer Mode時は `reviewTargetForStudent`
- PC表示とスマートフォン表示の違い：
  - 主要導線はスマートフォン下部タブ中心
  - 一部グリッドやリストはCSSのメディアクエリでPC向けに横並び
  - `deck-builder` はPCで2カラム、スマホで1カラム
  - 詳細は `app/globals.css` のレスポンシブCSSに依存

## 2. 画面一覧

### URLを持つ画面・ルート

| 画面名 | URL・ルート | 対象ユーザー | 主な目的 | 主なコンポーネント | 遷移元 | 遷移先 |
| --- | ------- | ------ | ---- | --------- | --- | --- |
| ランディング | `/` | 未ログイン | RecaLoop紹介、ログイン導線 | `app/page.tsx` | 直接アクセス | `/login` |
| ログイン / 新規登録 | `/login` | 未ログイン | メール認証、登録、パスワード再設定メール | `app/login/page.tsx` | `/`, 認証ガード | `/dashboard`, `/auth/update-password` |
| 認証後メイン | `/dashboard` | ログイン済み | メインアプリ全体 | `app/dashboard/page.tsx`, `PersonalApp` | `/login`, 直接アクセス | `?view=...` 内部ビュー |
| ダッシュボード認証ガード | `/dashboard/*` layout | ログイン済み | セッション確認 | `app/dashboard/layout.tsx` | `/dashboard` 配下 | `/login` または children |
| 初回設定リダイレクト | `/setup` | ログイン済み | 現在は `/dashboard` へ誘導 | `app/setup/page.tsx` | 旧オンボーディング導線 | `/dashboard` |
| パスワード更新 | `/auth/update-password` | パスワードリセット中 | 新パスワード設定 | `app/auth/update-password/page.tsx` | メールリンク | `/dashboard` |
| 認証コールバック | `/auth/callback` | Supabase callback | code exchange | `app/auth/callback/route.ts` | Supabaseメール/OAuth | `next` または `/login?error=...` |
| 管理者投稿申請 | `/admin/submissions` | admin | 投稿申請の承認・却下 | `AdminSubmissions` | 直接アクセス | `/dashboard` |
| デッキ作成専用ページ | `/deck-builder` | ログイン不要 | ローカルCSV + メディアから `.recaloop` 作成 | `app/deck-builder/page.tsx` | 直接アクセス | ファイルダウンロード |
| 公開ライブラリ | `/library` | 旧公開導線 | 現在はデッキ画面へリダイレクト | `app/library/page.tsx` | 旧導線 | `/dashboard?view=decks` |
| ランキング | `/rankings` | 旧公開導線 | 現在はデッキ画面へリダイレクト | `app/rankings/page.tsx` | 旧導線 | `/dashboard?view=decks` |
| カード配布リンク | `/share/cards/[token]` | 旧配布導線 | 現在はデッキ画面へリダイレクト | `app/share/cards/[token]/page.tsx` | 旧共有リンク | `/dashboard?view=decks` |
| 教材配布リンク | `/share/material/[token]` | 旧配布導線 | 現在はデッキ画面へリダイレクト | `app/share/material/[token]/page.tsx` | 旧共有リンク | `/dashboard?view=decks` |
| Web App Manifest | `/manifest.webmanifest` | PWA | PWAメタデータ | `app/manifest.ts` | ブラウザ | なし |

### URLを持たないメインアプリ内ビュー

| 画面名 | URL・ルート | 対象ユーザー | 主な目的 | 主なコンポーネント | 遷移元 | 遷移先 |
| --- | ------- | ------ | ---- | --------- | --- | --- |
| Home | `/dashboard?view=home` または初期表示 | 全ユーザー | 今日の予定・復習・Cafe入口・最近の教材 | `HomeView` | BottomNav | Study, Calendar, Cafe, Settings, Decks |
| 学習 | `/dashboard?view=study` | 全ユーザー | 学習入口、タイマー系Coming Soon | `StudyHub`, `FeatureCard` | BottomNav | Reviews, Materials |
| 教材 | `/dashboard?view=materials` / `decks` | 全ユーザー | デッキ一覧、作成、インポート | `MaterialsHub`, `DeckList` | BottomNav, Home, Study | Deck detail, Add sheet |
| 進捗 | `/dashboard?view=progress` | 全ユーザー | 学習時間・問題数・ヒートマップ・称号導線 | `ProgressHub`, `LearningHeatmap` | BottomNav | Calendar, Titles |
| Cafe | `/dashboard?view=cafe` | 全ユーザー | Cafe Coming Soon | `CafeHub`, `FeatureGrid` | BottomNav, Homeショップカード | Notices |
| 復習 | `/dashboard?view=reviews` | 全ユーザー | 今日の復習、まとめて保存 | `ReviewView`, `HierarchicalTargetList` | Study, Home | Study session |
| カレンダー | `/dashboard?view=calendar` | 全ユーザー | 月間予定、予定移動・削除 | `CalendarView`, `SelectableTargetTree` | BottomNav, Progress | Study session |
| 生徒 | `/dashboard?view=students` | teacher | 生徒一覧、招待コード、生徒詳細 | `StudentsView`, `StudentDetail`, `AssignmentCreator` | AppTopBar role button | Viewer Mode, Assignment |
| 課題 | `/dashboard?view=assignments` | student / viewer | 担当教師連携、課題一覧、課題詳細 | `AssignmentsView`, `AssignmentList`, `AssignmentCard` | AppTopBar role button, Home | Study session |
| 称号 | `/dashboard?view=titles` | 全ユーザー | 称号一覧・装備 | `TitlesView` | Progress, Settings | Settings |
| 設定 | `/dashboard?view=settings` | 全ユーザー | アカウント・学習・外観・ストレージ | `SettingsView` / `ViewerSettings` | AppTopBar, Homeショップカード | Login after logout |
| お知らせ | `/dashboard?view=notices` | 全ユーザー | お知らせ・ロードマップ | `NoticesView` | AppTopBar, FeatureDialog | なし |
| デッキ詳細 | 内部state `detail` | 全ユーザー | 問題一覧、CSV、選択、学習、エクスポート | `MaterialDetail` / `WordDetail` | DeckList | Study, DetailView, CSV Dialog |
| 1問/まとめて学習 | 内部state `study` | 全ユーザー | 問題表示、メディア、評価、スキップ | `StudyView`, `StudySessionTracker` | Home, Reviews, Deck detail, Calendar, Assignment | 元画面 |
| 問題詳細 | 内部state `history` | 全ユーザー | 評価履歴、カード編集、メディア編集 | `DetailView`, `CardMediaEditor` | Deck detail | 元画面 |

### URLを持たないモーダル・ボトムシート・ダイアログ

| UI名 | 使用画面 | 目的 | ファイル・関数 | 備考 |
| --- | --- | --- | --- | --- |
| デッキ追加ボトムシート | 教材一覧 | 新規デッキ作成、`.recaloop`インポート | `DeckList` | `.bottom-sheet` |
| デッキ操作ボトムシート | 教材一覧 | 開く、削除 | `DeckList` | ellipsisから表示 |
| CSVインポートモーダル | デッキ詳細 | CSVプレビュー・インポート | `CsvDialog` | 中央モーダル風 |
| Feature Dialog | Study / Progress / Cafe | Coming Soon説明 | `FeatureDialog` | 中央ダイアログ風 |
| 称号獲得ダイアログ | 評価保存後 | 称号獲得・完走演出 | `TitleEarnedDialog` | `achievement-backdrop` |
| 計画作成ダイアログ | デッキ選択モード | 開始日・終了日・曜日指定 | `SelectionPanel` | `stats-dialog` |
| 期限変更ダイアログ | 課題一覧 | 一括期限変更 | `AssignmentList` | `stats-dialog` |
| 課題編集パネル | 課題詳細 | 期限変更、問題追加、削除 | `AssignmentEditor` | カード内展開 |
| カレンダー移動ダイアログ | カレンダー | 予定を他の日へ移動 | `CalendarView` | `stats-dialog` |
| 画像拡大オーバーレイ | 学習画面 | 画像拡大・ピンチ・ドラッグ | `ImageZoomOverlay` | Escapeでも閉じる |
| Toast | メインアプリ全体 | 保存完了など | `PersonalApp` state | 画面下部表示 |
| Loading Overlay | メインアプリ初期ロード | コーヒーカップローダー | `LoadingOverlay`, `CoffeeLoader` | `読み込み中`テキスト自体はラベルに残る |

## 3. ナビゲーション構造

```text
/
└─ /login
   ├─ 新規登録
   ├─ パスワード再設定メール
   └─ /dashboard

/auth/callback
└─ /dashboard または /login?error=auth_callback

/auth/update-password
└─ /dashboard

/dashboard
├─ Home
│  ├─ 設定
│  ├─ Cafe
│  ├─ 今日の予定 → 学習 または Calendar
│  ├─ 今日の復習 → 学習 または Reviews
│  └─ 最近の教材 → 教材
├─ Study
│  ├─ 問題を解く → Reviews
│  ├─ タイマー → Coming Soon Dialog
│  ├─ ポモドーロ → Coming Soon Dialog
│  ├─ 勉強時間をあとから記録 → Coming Soon Dialog
│  └─ 教材から選ぶ → 教材
├─ 教材
│  ├─ デッキ追加ボトムシート
│  │  ├─ 新規デッキ作成
│  │  └─ .recaloop インポート
│  ├─ デッキ操作ボトムシート
│  │  ├─ 開く
│  │  └─ 削除
│  └─ デッキ詳細
│     ├─ 学習開始 → 学習画面
│     ├─ CSVインポート
│     ├─ .recaloop エクスポート
│     ├─ 選択モード
│     │  ├─ まとめて学習 → 学習画面
│     │  ├─ 計画作成 → Calendar
│     │  └─ 一括削除
│     ├─ 問題行タップ → 1問だけ学習
│     └─ 詳細 → 問題詳細
├─ Calendar
│  ├─ 月切り替え
│  ├─ 日付選択
│  ├─ この日の学習を開始 → 学習画面
│  ├─ スケジュールから削除
│  └─ 他の日へ移動
├─ Summary
│  ├─ Calendar
│  ├─ Titles
│  └─ ヒートマップ
├─ Cafe
│  └─ Coming Soon
├─ Reviews
│  ├─ まとめて復習 → 学習画面
│  ├─ まとめて保存
│  └─ 個別評価保存
├─ Settings
│  ├─ アカウント
│  ├─ 学習
│  ├─ 外観
│  ├─ データとストレージ
│  └─ ログアウト → /login
├─ Notices
│  └─ ロードマップ
├─ teacherのみ Students
│  ├─ 招待コード作成・更新・コピー・共有
│  ├─ 生徒詳細
│  │  ├─ この生徒の画面を見る → Viewer Mode
│  │  ├─ 課題作成
│  │  └─ 課題一覧
│  └─ 連携解除
└─ studentのみ Assignments
   ├─ 担当教師連携
   ├─ 課題一覧
   ├─ 課題詳細
   └─ 課題学習 → 学習画面

/admin/submissions
├─ 申請一覧
├─ 申請詳細
├─ 承認
└─ 却下

/deck-builder
├─ デッキ名・説明・cards.csv入力
├─ メディア追加
├─ [ファイル名]挿入
└─ .recaloop ダウンロード

/library, /rankings, /share/cards/[token], /share/material/[token]
└─ /dashboard?view=decks にリダイレクト
```

## 4. 各画面の詳細

### ランディング

- ルート：`/`
- 対象ユーザー：未ログイン
- 画面の目的：RecaLoopの概要紹介とログイン導線
- 使用ファイル：`app/page.tsx`
- 読み込んでいる主要コンポーネント：Next `Link`, `lucide-react` icons
- 表示条件：常時
- データ取得元：なし
- 主な操作：ログイン画面へ移動
- 遷移先：`/login`
- モーダル・ボトムシート：なし
- ローディング状態：なし
- 空状態：なし
- エラー状態：なし

#### 現在の画面構成

```text
Landing
├─ アイコン画像 /icon.svg
├─ アプリ名 RecaLoop
├─ 説明文
├─ 機能説明リスト
│  ├─ 階層つきデッキ
│  └─ 復習管理
└─ CTA「ログインして始める」
```

### ログイン / 新規登録

- ルート：`/login`
- 対象ユーザー：未ログイン
- 画面の目的：メール・パスワード認証、新規登録、再設定メール
- 使用ファイル：`app/login/page.tsx`
- 読み込んでいる主要コンポーネント：Supabase client, `Eye`, `EyeOff`, `Mail`, `Lock`
- 表示条件：常時。すでにログイン済みかどうかのリダイレクトはこの画面内では明示されていない
- データ取得元：Supabase Auth
- 主な操作：ログイン、新規登録、パスワードリセットメール送信
- 遷移先：`/dashboard`
- モーダル・ボトムシート：なし
- ローディング状態：送信ボタンの `送信中...`
- 空状態：なし
- エラー状態：Supabase Auth errorを日本語化して表示

#### 現在の画面構成

```text
Login
├─ ブランド領域
│  ├─ RecaLoop
│  └─ キャッチコピー
├─ タブ
│  ├─ ログイン
│  └─ 新規登録
├─ Email入力
├─ Password入力
│  ├─ 表示/非表示
│  ├─ Caps Lock警告
│  └─ 前後空白警告
├─ エラーメッセージ
├─ 送信ボタン
└─ パスワードを忘れた場合
```

### パスワード更新

- ルート：`/auth/update-password`
- 対象ユーザー：パスワード再設定リンクから来たユーザー
- 画面の目的：新しいパスワードを登録
- 使用ファイル：`app/auth/update-password/page.tsx`
- データ取得元：Supabase Auth
- 主な操作：パスワード更新
- 遷移先：`/dashboard`
- エラー状態：6文字未満、Supabase error

### Home

- ルート：`/dashboard` 初期表示 / `?view=home`
- 対象ユーザー：全ユーザー
- 画面の目的：今日の学習入口、Cafe入口、最近の教材への導線
- 使用ファイル：`components/personal-app.tsx`
- 読み込んでいる主要コンポーネント：`HomeView`, `BottomNav`, `AppTopBar`
- 表示条件：`view === "home"` かつ detail/study/history がない
- データ取得元：`loadAppData`, `scheduledTargetsForUser`, `dueTargets`, `learningDays`
- 主な操作：予定学習開始、復習開始、Cafeへ移動、設定へ移動、教材へ移動
- 遷移先：`study`, `calendar`, `reviews`, `materials`, `cafe`, `settings`
- モーダル・ボトムシート：なし
- ローディング状態：アプリ初期ロード中は `LoadingOverlay`
- 空状態：最近の教材がない場合 `まだ教材がありません`
- エラー状態：アプリ全体の `読み込みに失敗しました`

#### 現在の画面構成

```text
Home
├─ AppTopBar
│  ├─ お知らせ
│  ├─ teacher/student role導線
│  └─ 設定
├─ ショップカード / home-shop-card
│  ├─ アカウントアイコン
│  ├─ ニックネーム
│  ├─ ID表示
│  ├─ chevron
│  ├─ 区切り線
│  ├─ 累計来店
│  ├─ 来店中
│  ├─ 勉強時間
│  ├─ 問題数
│  └─ カフェ内部風イラスト
├─ 今日の学習 2列ボタン
│  ├─ 今日の予定
│  │  ├─ 件数
│  │  └─ 約分数
│  └─ 今日の復習
│     ├─ 件数
│     └─ 完了件数
├─ 今日の進捗カード
│  ├─ 今日の進捗
│  ├─ N件中M件完了
│  ├─ 予想時間
│  ├─ 進捗バー
│  └─ CTA「続きから」または「教材を見る」
└─ 最近の教材
   ├─ すべてボタン
   ├─ 教材リスト行
   │  ├─ アイコン
   │  ├─ 教材名
   │  ├─ 件数・進捗
   │  └─ chevron
   └─ 空状態「まだ教材がありません」
```

### 学習

- ルート：`/dashboard?view=study`
- 対象ユーザー：全ユーザー
- 画面の目的：学習関連機能の入口
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`StudyHub`, `FeatureCard`, `FeatureListRow`
- データ取得元：`scheduledTargetsForUser`, `dueTargets`
- 主な操作：予定開始、復習を見る、教材から選ぶ、Coming Soon表示
- 遷移先：`reviews`, `materials`, `notices`

#### 現在の画面構成

```text
Study
├─ 今日の対象カード
│  ├─ 今日の対象N件 / 学習を始めましょう
│  ├─ 予定N件 ・ 復習N件
│  └─ CTA「予定を始める」または「復習を見る」
├─ 2列アクショングリッド
│  ├─ 問題を解く
│  ├─ タイマー
│  ├─ ポモドーロ
│  └─ 勉強時間をあとから記録
└─ その他リスト
   ├─ 教材から選ぶ
   ├─ カフェ集中
   └─ リスニング
```

### 教材一覧

- ルート：`/dashboard?view=materials` または `?view=decks`
- 対象ユーザー：全ユーザー、Viewer Mode時は生徒データ
- 画面の目的：デッキ一覧、検索、並び替え、作成、インポート、削除
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`MaterialsHub`, `DeckList`
- データ取得元：`data.materialDecks`, `data.wordLists`, `loadAppData`, `.recaloop` import functions
- 主な操作：検索、並び替え、デッキ追加、`.recaloop`インポート、デッキを開く、削除
- 遷移先：デッキ詳細
- モーダル・ボトムシート：デッキ追加ボトムシート、デッキ操作ボトムシート
- ローディング状態：`.recaloop を準備しています`、カード/メディア進捗
- 空状態：`まだデッキがありません`
- エラー状態：インポートエラーを notice 表示

#### 現在の画面構成

```text
教材一覧
├─ iOS風ページナビ
│  ├─ 見出し「教材」
│  └─ plusボタン
├─ エラー表示
├─ インポート進捗
├─ ツールバー
│  ├─ 検索
│  └─ 並び替えselect
├─ デッキリスト
│  ├─ デッキ行
│  │  ├─ アイコン
│  │  ├─ タイトル
│  │  ├─ 件数・進捗・期限
│  │  ├─ chevron
│  │  └─ ellipsis
│  └─ 空状態
├─ デッキ追加ボトムシート
│  ├─ 新規デッキ名
│  ├─ 作成
│  ├─ .recaloop インポート
│  └─ キャンセル
└─ デッキ操作ボトムシート
   ├─ 開く
   ├─ 削除
   └─ 閉じる
```

### デッキ詳細

- ルート：内部state `detail`
- 対象ユーザー：全ユーザー、Viewer Mode時は生徒データ
- 画面の目的：デッキ内の問題・カード管理、学習、CSV、選択、エクスポート
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`MaterialDetail`, `WordDetail`, `MaterialTree`, `WordCardTree`, `RatingEditor`, `SelectionPanel`, `CsvDialog`
- データ取得元：`loadMaterialNodes`, `loadWordCards`, `dataWithDeckContent`
- 主な操作：学習開始、チェックのみ表示、CSVインポート、`.recaloop`エクスポート、選択、詳細、編集、削除、評価保存
- 遷移先：学習画面、問題詳細
- モーダル・ボトムシート：CSVモーダル、計画作成ダイアログ、エクスポート確認は `confirm` / `prompt`

#### 現在の画面構成

```text
デッキ詳細
├─ 戻るリンク
├─ PageTitle
│  ├─ デッキ名
│  └─ 件数など
├─ アクションボタン
│  ├─ 学習開始
│  ├─ 全てのチェックを見る
│  ├─ CSVインポート
│  ├─ .recaloop エクスポート
│  └─ 選択
├─ タイトル編集
├─ デッキメタ情報編集
├─ 復習ルール
├─ 選択モードパネル
│  ├─ まとめて学習
│  ├─ 計画作成
│  └─ 一括削除
├─ まとめて保存
└─ 階層ツリー
   ├─ folder
   │  ├─ 開閉状態をlocalStorage保持
   │  ├─ 選択モード時チェック
   │  └─ 子folder / item
   └─ item/card
      ├─ タップで1問学習
      ├─ 詳細
      ├─ 編集/削除
      └─ RatingEditor
```

### 学習画面

- ルート：内部state `study`
- 対象ユーザー：全ユーザー、Viewer Mode時は生徒対象
- 画面の目的：1問または複数問の連続学習と評価保存
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`StudyView`, `StudySessionTracker`, `ImageZoomOverlay`
- データ取得元：渡された `ReviewTarget[]`、ローカルメディアIndexedDB
- 主な操作：裏面を見る、評価保存、チェック保存、スキップ、画像拡大、内容ON/OFF
- 遷移先：元画面に戻る
- ローディング状態：メディア取得中は個別表示。アプリ全体の初期ロードとは別
- 空状態：対象がない場合の具体表示はコード上の詳細確認が必要
- エラー状態：保存失敗時はエラー表示

#### 現在の画面構成

```text
学習画面
├─ 戻る/終了
├─ 現在位置・パンくず
├─ 内容 ON/OFF
├─ 表面
│  ├─ 問題番号
│  ├─ 表面テキスト
│  ├─ 表面画像
│  └─ 表面音声
├─ 裏面を見る
├─ 裏面
│  ├─ 裏面テキスト
│  ├─ 裏面画像
│  └─ 裏面音声
├─ 評価ボタン
│  ├─ もう一回
│  ├─ 難しい
│  ├─ 正解
│  └─ 簡単
└─ スキップ
```

### 復習

- ルート：`/dashboard?view=reviews`
- 対象ユーザー：全ユーザー
- 画面の目的：期限が来た問題を復習
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`ReviewView`, `BatchSavePanel`, `HierarchicalTargetList`, `ReviewRow`
- データ取得元：`dueTargets(data)`
- 主な操作：まとめて復習、まとめて保存、個別評価
- 遷移先：学習画面
- 空状態：`今日の復習は完了です。`

#### 現在の画面構成

```text
復習
├─ PageTitle「復習」
├─ 今日の復習カード
│  ├─ 合計件数
│  ├─ 期限切れ件数
│  └─ まとめて復習
├─ まとめて保存
└─ デッキ別・階層別リスト
   └─ ReviewRow
      ├─ 問題タイトル
      ├─ 裏面/メモ
      └─ RatingEditor
```

### カレンダー

- ルート：`/dashboard?view=calendar`
- 対象ユーザー：全ユーザー
- 画面の目的：月間予定確認、予定の学習・移動・削除
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`CalendarView`, `SelectableTargetTree`, `DateInput`
- データ取得元：`studyPlans`, `studyPlanItems`, `targetByPlanItem`
- 主な操作：前月/次月、日付選択、この日の学習、予定選択、移動、削除
- 遷移先：学習画面
- モーダル・ボトムシート：移動先日付ダイアログ
- 空状態：`この日の予定はありません。`
- エラー状態：予定階層読み込み失敗時に toast

#### 現在の画面構成

```text
カレンダー
├─ PageTitle「カレンダー」
│  ├─ 前月
│  └─ 次月
├─ 月間カレンダー
│  ├─ 曜日行
│  └─ 42日グリッド
│     ├─ 日付
│     └─ 予定数
├─ 選択日の詳細
│  ├─ 日付
│  ├─ 予定枚数
│  ├─ この日の学習を開始
│  └─ 階層選択ツリー
└─ 操作
   ├─ スケジュールから削除
   └─ 他の日へ移動
```

### 進捗

- ルート：`/dashboard?view=progress`
- 対象ユーザー：全ユーザー
- 画面の目的：学習統計・ヒートマップ・称号導線
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`ProgressHub`, `LearningHeatmap`, `FeatureGrid`
- データ取得元：`studySessions`, `attempts`, `materialDecks`, `wordLists`
- 主な操作：Calendarへ移動、Titlesへ移動、Coming Soon確認

#### 現在の画面構成

```text
進捗
├─ PageTitle「進捗」
├─ ミニ統計
│  ├─ 累計学習時間
│  ├─ 問題数
│  └─ 今日の復習
├─ 進捗リンク
│  ├─ カレンダー
│  └─ 称号
├─ 学習ヒートマップ
├─ 教材別・教科別の基本集計
└─ progressカテゴリFeatureGrid
```

### Cafe

- ルート：`/dashboard?view=cafe`
- 対象ユーザー：全ユーザー
- 画面の目的：Cafe機能のComing Soon表示
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`CafeHub`, `FeatureGrid`
- データ取得元：`features`
- 主な操作：Coming Soon機能詳細表示
- 実装状況：UIのみ

#### 現在の画面構成

```text
Cafe
├─ PageTitle「カフェ」
├─ cafe-coming
│  ├─ Coffeeアイコン
│  ├─ Study → EXP → Cafe
│  ├─ COMING SOON
│  ├─ ただいま開店準備中です
│  └─ 説明文
└─ cafeカテゴリFeatureGrid
   ├─ マイカフェ
   ├─ お客さん
   ├─ 模様替え
   ├─ ショップ
   └─ カフェランキング
```

### 設定

- ルート：`/dashboard?view=settings`
- 対象ユーザー：全ユーザー。Viewer Mode時は閲覧専用
- 画面の目的：プロフィール、認証、学習属性、外観、ローカルストレージ、ログアウト
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`SettingsView`, `ViewerSettings`, `SettingsGroup`, `SettingsFormRow`, `ThemeColorPicker`, `LocalStoragePanel`
- データ取得元：`profile`, Supabase Auth, IndexedDB local media
- 主な操作：アイコン変更、ニックネーム保存、ID確認、メール変更、パスワード変更、年代/学年/志望校/権限/称号保存、テーマ色変更、未使用メディア削除、ログアウト
- ローディング状態：一部ボタン内に `確認中...`
- エラー状態：authMessage, notice, local media取得失敗toast

#### 現在の画面構成

```text
設定
├─ iOSページナビ「設定」
├─ プロフィールカード
│  ├─ アイコン画像 picker
│  ├─ ニックネーム
│  ├─ ID
│  └─ アイコン変更説明
├─ アカウント
│  ├─ ニックネーム
│  ├─ ID
│  ├─ メール
│  ├─ メール変更
│  ├─ 確認メールを送る
│  ├─ パスワード
│  └─ パスワードを変更
├─ 学習
│  ├─ 年代
│  ├─ 学年
│  ├─ 志望校
│  ├─ 権限
│  ├─ 称号
│  └─ 保存
├─ 外観
│  ├─ 文字色
│  ├─ アクセント
│  └─ ベース
├─ データとストレージ
│  ├─ 端末内メディア
│  ├─ 未使用
│  ├─ 再計算
│  ├─ 未使用をクリア
│  └─ メディア一覧上位6件
└─ その他
   ├─ 通知
   ├─ アプリ情報
   └─ ログアウト
```

### 先生画面

- ルート：`/dashboard?view=students`
- 対象ユーザー：teacher
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`StudentsView`, `StudentDetail`, `AssignmentCreator`, `AssignmentList`
- データ取得元：`teacherLinks`, `invite_code`, `assignments`, `assignmentItems`, student decks
- 主な操作：招待コード作成/更新、コピー、共有、生徒解除、生徒詳細、この生徒の画面を見る、課題作成、課題編集

#### 現在の画面構成

```text
先生 / 生徒管理
├─ 招待コードカード
│  ├─ 未発行時「招待コード作成」
│  └─ 発行済み
│     ├─ コード
│     ├─ コピー
│     ├─ 共有
│     └─ 更新
├─ 生徒一覧
│  ├─ 生徒名
│  ├─ 学年/志望校
│  ├─ 詳細
│  └─ 解除
└─ 生徒詳細
   ├─ 概要
   ├─ この生徒の画面を見る
   ├─ 課題進捗
   ├─ 課題を作成
   └─ 課題一覧
```

### 生徒課題画面

- ルート：`/dashboard?view=assignments`
- 対象ユーザー：student または Viewer Mode
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`AssignmentsView`, `AssignmentList`, `AssignmentCard`, `BatchSavePanel`
- データ取得元：`assignments`, `assignmentItems`, `teacherLinks`
- 主な操作：担当教師連携、連携解除、課題表示、課題学習、評価・チェック保存

#### 現在の画面構成

```text
課題
├─ 担当教師カード
│  ├─ 担当教師名 または 未連携
│  ├─ 招待コード入力
│  ├─ 連携
│  └─ 連携解除
└─ 課題一覧
   ├─ 課題カード
   │  ├─ タイトル
   │  ├─ デッキ名
   │  ├─ 期限
   │  ├─ 対象生徒
   │  ├─ 完了数/全体数
   │  ├─ 完了率
   │  └─ 開閉
   └─ 課題詳細
      ├─ メトリクス
      ├─ まとめて保存
      └─ 階層表示
```

### 問題詳細

- ルート：内部state `history`
- 対象ユーザー：全ユーザー、Viewer Mode時は生徒対象
- 使用ファイル：`components/personal-app.tsx`
- 主要コンポーネント：`DetailView`, `CardMediaEditor`, `RatingEditor`
- データ取得元：`materialAttempts`, `wordAttempts`, local media
- 主な操作：評価履歴編集、履歴削除、カードメディア追加/削除

#### 現在の画面構成

```text
問題詳細
├─ PageTitle
├─ カード/問題概要
├─ 現在state
├─ 学習回数
├─ 前回学習日
├─ 次回復習予定
├─ 暗記カードの場合メディア編集
└─ 評価履歴
   ├─ rating
   ├─ unknown_flag
   ├─ created_at
   ├─ 編集
   └─ 削除
```

### デッキ作成専用ページ

- ルート：`/deck-builder`
- 対象ユーザー：ログイン不要
- 画面の目的：手元のCSVとメディアから `.recaloop` を生成
- 使用ファイル：`app/deck-builder/page.tsx`
- 主要コンポーネント：ページ内直接実装
- データ取得元：ローカルstate、File API
- 主な操作：デッキ名入力、説明入力、cards.csv編集、メディア追加、`[ファイル名]`挿入、`.recaloop`書き出し、再ダウンロード
- モーダル・ボトムシート：`prompt` / `confirm`
- ローディング状態：ボタン `書き出し中...`
- エラー状態：`message` にエラー表示

#### 現在の画面構成

```text
Deck Builder
├─ ヘッダー
│  ├─ ローカル専用・ログイン不要
│  ├─ RecaLoop デッキ作成
│  ├─ 説明文
│  └─ .recaloopを書き出す
├─ ダウンロード状態 sticky section
│  ├─ message
│  └─ 再ダウンロード
├─ 左カラム
│  ├─ デッキ名
│  ├─ 説明
│  ├─ cards.csv textarea
│  └─ 形式説明
└─ 右カラム
   ├─ メディア
   ├─ ドラッグ&ドロップ/ファイル選択
   └─ メディアリスト
      └─ [ ] 挿入
```

### 管理者投稿申請

- ルート：`/admin/submissions`
- 対象ユーザー：admin
- 使用ファイル：`app/admin/submissions/page.tsx`, `components/admin-submissions.tsx`
- データ取得元：`loadSubmissions`, `loadAdminContent`, `moderateSubmission`
- 主な操作：申請選択、承認、却下
- 空状態：`申請はありません。`
- エラー状態：読み込み・承認・却下エラーを `notice`

#### 現在の画面構成

```text
Admin Submissions
├─ ヘッダー
│  ├─ ADMIN
│  ├─ 投稿申請
│  └─ マイページ
├─ 申請一覧
│  ├─ タイトル
│  ├─ 種別
│  └─ ステータス
└─ 詳細
   ├─ タイトル
   ├─ 説明
   ├─ 注意表示
   ├─ ツリー/カード一覧
   ├─ 承認
   └─ 却下
```

### 旧公開ライブラリ・ランキング・共有リンク

- ルート：`/library`, `/rankings`, `/share/cards/[token]`, `/share/material/[token]`
- 現状：すべて `/dashboard?view=decks` へリダイレクト
- 備考：
  - `components/library-app.tsx`、`components/rankings-app.tsx`、`components/shared-content.tsx` は存在する
  - ただし現在のルートからは直接レンダリングされていない
  - データ関数 `loadLibrary`, `loadRankings`, `copyShared*` などは `lib/recaloop-data.ts` に残っている

## 5. Home画面の詳細

### 最上部から最下部までの表示順

```text
Home
├─ AppTopBar
├─ ショップカード
├─ 今日の予定 / 今日の復習 2列ボタン
├─ 今日の進捗カード
├─ 最近の教材
└─ BottomNav
```

### 各カード・ボタンの名称

- ショップカード
  - ニックネーム
  - ID
  - 累計来店
  - 来店中
  - 勉強時間
  - 問題数
  - カフェ内部風イラスト
- 2列ボタン
  - 今日の予定
  - 今日の復習
- 今日の進捗
  - `今日の進捗`
  - `続きから` または `教材を見る`
- 最近の教材
  - `すべて`
  - 教材名行

### 2列表示・1列表示

- `home-today-actions` は2列ボタン
- 最近の教材はリスト
- レスポンシブの詳細はCSSに依存

### 横スクロールの有無

- コード上、Homeの主要構成に明示的な横スクロールは確認できない

### 表示条件

- ショップカード：常時
- 今日の予定：予定数が0でも表示
- 今日の復習：復習数が0でも表示
- 最近の教材：最大3件。0件なら空状態

### ユーザー種別による違い

- Home本体は基本同じ
- `AppTopBar` のrole導線が teacher / student / none で変わる
- Viewer Mode時はデータが生徒対象になる

### データが存在しない場合の挙動

- 今日の予定/復習がない場合もボタンは表示され、Calendar/ReviewsやMaterialsへ誘導
- 最近の教材がない場合は `まだ教材がありません`

### Homeから直接実行できる機能

- 今日の予定を開始
- 今日の復習を開始
- 教材へ移動
- Cafeへ移動
- 設定へ移動
- お知らせへ移動

### Homeに表示されていないが、他画面には存在する主要機能

- CSVインポート
- `.recaloop`インポート/エクスポート
- デッキ詳細の選択モード
- 計画作成
- カレンダー予定移動/削除
- 課題作成・編集
- 先生/生徒招待コード
- 称号一覧
- ローカルメディアストレージ管理
- 管理者投稿申請
- デッキ作成専用ページ

## 6. Cafe機能の詳細

| 項目 | 現状 | 備考 |
| --- | --- | --- |
| Cafeの入口 | 一部実装 | BottomNav Cafe、Homeショップカードから遷移 |
| メイン画面 | UIのみ | `CafeHub` にComing Soon表示 |
| ショップ | 未実装 | `features` に `shop` はあるが操作なし |
| アイテム | 未実装 | コード上で実体データ確認できず |
| カスタマイズ | 未実装 | `interior` featureのみ |
| 背景 | 未実装 | CSS装飾のみ |
| 家具 | 未実装 | feature説明のみ |
| アバター・アイコン | 一部実装 | 設定でプロフィールアイコン画像をlocalStorage保存 |
| EXP | 一部実装 | 既存プロフィール/称号/評価保存と連動。Cafeとは未接続 |
| レベル | 一部実装 | Home/設定周辺で直接目立つ表示は少ない |
| 通貨・豆などの報酬 | 未実装 | 実データなし |
| ローディング中のコーヒーカップ | 実装済み | `CoffeeLoader` |
| 勉強機能との連動 | 未実装 | `Study → EXP → Cafe` の説明のみ |
| 未実装・仮実装・ダミー表示 | UIのみ | 偽ランキングや操作可能な報酬は表示しない設計 |

### Cafeの現在画面

```text
Cafe
├─ PageTitle
├─ COMING SOONカード
├─ 機能説明
└─ FeatureGrid
```

## 7. 共通コンポーネント

| コンポーネント | ファイルパス | 使用画面 | 主なprops | 見た目の特徴 | 重複・備考 |
| --- | --- | --- | --- | --- | --- |
| `PersonalApp` | `components/personal-app.tsx` | `/dashboard` | なし | メインアプリ全体をstateで制御 | 1ファイルに多数UIが集約 |
| `AppTopBar` | `components/personal-app.tsx` | Home/Study/Progress/Cafe | roleNav, navigate, active | 右上通知・role・設定 | quiet viewでは非表示 |
| `BottomNav` | `components/personal-app.tsx` | dashboard全体 | view, navigate, badges | 下部固定5タブ | `AppRouteNav`にも下部navがあり重複 |
| `PageTitle` | `components/personal-app.tsx` | 多数のサブ画面 | title, sub, action | 戻るボタン付き見出し | subはpropsにあるが現在表示されない実装 |
| `CoffeeLoader` | `components/coffee-loader.tsx` | 初期ロード、LibraryApp | label, compact | コーヒーカップ液体アニメ | LoadingOverlayから利用 |
| `LoadingOverlay` | `components/personal-app.tsx` | 初期ロード | label | 中央ローディング | テキストはaria-label中心 |
| `FeatureCard` | `components/personal-app.tsx` | Study/Progress/Cafe | feature, navigate | status label + title + description | Coming Soon dialogを開く |
| `FeatureGrid` | `components/personal-app.tsx` | Progress/Cafe | category, navigate | feature card grid | foundation.tsと連動 |
| `FeatureDialog` | `components/personal-app.tsx` | FeatureCard | feature, close, roadmap | 中央ダイアログ | ボトムシートではない |
| `DeckList` | `components/personal-app.tsx` | 教材一覧 | data, setData, open, flash | iOS風リスト + bottom sheet | material/word両方を統合表示 |
| `MaterialTree` / `WordCardTree` | `components/personal-app.tsx` | デッキ詳細 | nodes/cards等 | 階層トグル | 開閉状態localStorage |
| `SelectableTargetTree` | `components/personal-app.tsx` | 課題作成、カレンダー、選択 | entries, selected, setSelected | 階層選択UI | 親階層一括選択あり |
| `StoredDetails` | `components/personal-app.tsx` | 階層表示 | storageKey | details開閉をlocalStorage保持 | 多画面で使用 |
| `RatingEditor` | `components/personal-app.tsx` | 復習/詳細/課題/デッキ | target, save | 4段階評価 + チェック | 保存失敗表示あり |
| `BatchSavePanel` | `components/personal-app.tsx` | 復習/課題/デッキ | targets, save | まとめて保存 | 画面内で直接展開 |
| `CsvDialog` | `components/personal-app.tsx` | デッキ詳細 | target, close, committed | 中央モーダル | bottom sheetではない |
| `DateInput` | `components/personal-app.tsx` | 計画/課題/カレンダー | value, onChange | 共通date input | フォームは各所に直接配置 |
| `ImageZoomOverlay` | `components/personal-app.tsx` | 学習画面 | item, close | 暗いoverlay、pinch/drag | 背景クリックでは閉じない |
| `SettingsGroup` | `components/personal-app.tsx` | 設定 | title, children | iOS Settings風group | Settings専用 |
| `ThemeColorPicker` | `components/personal-app.tsx` | 設定 | title, value, options | 色選択ボタン | 外観専用 |
| `LocalStoragePanel` | `components/personal-app.tsx` | 設定 | data, flash | IndexedDBメディア容量 | local-media.ts使用 |
| `AdminSubmissions` | `components/admin-submissions.tsx` | `/admin/submissions` | なし | admin専用2カラム | 独立画面 |
| `LibraryApp` | `components/library-app.tsx` | 現在ルート未使用 | なし | 公開ライブラリUI | `/library` はredirectのため到達不能 |
| `RankingsApp` | `components/rankings-app.tsx` | 現在ルート未使用 | なし | ランキングUI | `/rankings` はredirect |
| `SharedContent` | `components/shared-content.tsx` | 現在ルート未使用 | type, token | 配布リンクUI | `/share/*` はredirect |
| `AppRouteNav` | `components/app-route-nav.tsx` | LibraryApp/RankingsApp想定 | active | route page用nav | main dashboard navと重複 |
| `HomeTabIcon`など | `components/nav-icons.tsx` | BottomNav | size等 | 独自線画SVG | lucide iconと混在 |
| `PwaRegister` | `components/pwa-register.tsx` | RootLayout | なし | service worker registration | UIなし |

## 8. 表示・デザインの現状

- 使用フォント：
  - `app/globals.css` でシステムフォント中心。詳細はCSS内定義に依存
  - 日本語はブラウザ/OSのシステムフォント
- 文字サイズ：
  - HomeやSettingsはiOS寄せのクラスが追加済み
  - 旧UI由来の `text-3xl`, `font-black`, `eyebrow` なども残存
- 余白：
  - `.app-page`, `.ios-screen`, `.surface`, `.card` など複数系統
  - 画面ごとに統一途上
- 角丸：
  - iOS風の大きな角丸と旧カード角丸が混在
- カード：
  - `surface`, `card`, `today-learning-card`, `home-shop-card`, `settings-group-card` など複数
  - Home/Settingsは比較的新しい構成
  - Review/Assignment/Calendarには旧surfaceカードも多い
- ボタン：
  - `primary-button`, `secondary-button`, `quiet-button`, `danger-button`, `ios-icon-button` が混在
  - 画面ごとに直接class指定あり
- 色：
  - CSS変数、テーマカラー、直接指定の色コードが混在
  - Settingsに文字色/アクセント/ベース変更機能あり
- アイコン：
  - `lucide-react`
  - `components/nav-icons.tsx` の独自SVG
  - `/icon.svg`
  - 一部アプリ内装飾
- 影：
  - 新旧CSSにより `shadow`, `box-shadow`, `surface` が混在
- 枠線：
  - `ring`, `border`, separator系CSSが混在
- タブバー：
  - 下部固定、5項目、badge対応
  - `AppRouteNav` 側にも別のbottom-nav実装あり
- レスポンシブ対応：
  - Tailwind風classとCSSメディアクエリが混在
  - スマホ優先の下部ナビ
  - `/deck-builder` は明示的にPC 2カラム
- iOS向け調整：
  - Safe Area、Settings group、bottom nav、iOS風listが存在
  - ただし全画面がiOSに統一されているわけではない
- アニメーション：
  - CoffeeLoader
  - bottom sheet / modal / overlayの詳細はCSS依存
- Reduce Motion対応：
  - CSS内に存在する可能性はあるが、この文書作成時点では具体箇所までは網羅確認していない

## 9. 重複・不整合・分かりにくい箇所

- 同じ機能への入口が複数ある
  - 復習：Home、Study、Reviews、BottomNav Study active
  - 教材：Home最近の教材、Studyその他、BottomNav Study、Materials/Decks view
  - カレンダー：BottomNav、Progressリンク、Home今日の予定
  - 称号：Progress、Settings
- 似た画面が重複している
  - `LibraryApp` / `RankingsApp` / `SharedContent` は残っているが、現在のルートではredirect
  - `AppRouteNav` と `BottomNav`
- 使用されていない可能性がある画面・コンポーネント
  - `components/library-app.tsx`
  - `components/rankings-app.tsx`
  - `components/shared-content.tsx`
  - `components/app-route-nav.tsx`
- 遷移先が見つからない/現在redirectされる導線
  - `/library`
  - `/rankings`
  - `/share/cards/[token]`
  - `/share/material/[token]`
- 表示名と機能名が一致していない可能性
  - `materials` と `decks` が両方存在し、UI表示は「教材」
  - 内部には `material_decks` と `word_lists` が残るが、UIは「デッキ」統合方向
  - 公開ライブラリ関連の関数名が残るが、現在UI上は非表示/redirect
- 生徒画面と先生画面で構造が不統一
  - teacher側課題一覧は編集・配布・期限変更があり、student側は担当教師連携がある
  - Viewer Modeでは生徒画面を先生権限で見るため、表示と権限が混ざりやすい
- モバイルで崩れる可能性
  - PageTitle actionに複数ボタンが入る画面
  - Calendarの月操作、課題カード内のaction-row
  - CSVモーダル、Admin画面、LibraryApp/RankingsApp旧画面
- テキストがはみ出す可能性
  - デッキ名、課題名、メディアファイル名、`.recaloop`ファイル名
  - `DeckBuilder` のdownload表示
- 中央揃えが崩れる可能性
  - 旧 `stats-dialog`, `csv-modal`, `achievement-dialog`
- 固定幅・固定高さが原因になりそうな箇所
  - DeckBuilderの `md:grid-cols-[1fr_320px]`
  - CSV textarea, media list
  - image zoom close button位置
- UIが直接ページ内に大量実装されている箇所
  - `components/personal-app.tsx` にHomeからSettingsまでほぼ全てが集約
  - `app/deck-builder/page.tsx` もページ内直接実装
- 似たカードやボタンのスタイルが複数存在する箇所
  - `card`, `surface`, `ios-list`, `today-learning-card`, `settings-group-card`
  - `primary-button`, `secondary-button`, `quiet-button`, Tailwind直接class

## 10. 現在実装されている機能一覧

| 機能名 | 主な画面 | 対象ユーザー | 実装状況 | Homeからのアクセス | 備考 |
| --- | ---- | ------ | ---- | ----------- | -- |
| ログイン | `/login` | 未ログイン | 実装済み | なし | Supabase Auth |
| アカウント作成 | `/login` | 未ログイン | 実装済み | なし | email confirmation |
| パスワード再設定 | `/login`, `/auth/update-password` | 未ログイン/認証中 | 実装済み | なし | reset email + update |
| Home | `/dashboard` | 全ユーザー | 実装済み | 直接 | メイン入口 |
| デッキ作成 | 教材一覧 | 全ユーザー | 実装済み | 間接 | 新規デッキ名のみ |
| デッキ編集 | デッキ詳細 | 全ユーザー | 一部実装 | 間接 | タイトル/説明など |
| 問題追加 | デッキ詳細 | 全ユーザー | 実装済み | 間接 | CSVまたは個別保存関数 |
| CSVインポート | デッキ詳細 | 全ユーザー | 実装済み | 間接 | `CsvDialog` |
| `.recaloop`インポート | 教材一覧 | 全ユーザー | 実装済み | 間接 | DeckList add sheet |
| `.recaloop`エクスポート | デッキ詳細 / deck-builder | 全ユーザー | 実装済み | 間接 | confirm/prompt使用 |
| APKGインポート | なし | 全ユーザー | 未実装 | なし | コード上で確認できない |
| 復習 | Reviews / Study | 全ユーザー | 実装済み | あり | 今日の復習 |
| 1問だけ学習 | デッキ詳細 | 全ユーザー | 実装済み | 間接 | item/cardタップ |
| まとめて学習 | 選択モード | 全ユーザー | 実装済み | 間接 | SelectionPanel |
| 一括評価/まとめて保存 | 復習/課題/デッキ | 全ユーザー | 実装済み | 間接 | BatchSavePanel |
| チェック保存 | RatingEditor | 全ユーザー | 実装済み | 間接 | 評価なし保存対応 |
| 課題作成 | 生徒詳細 | teacher | 実装済み | なし | AssignmentCreator |
| 課題提出/完了 | 課題詳細 | student/viewer | 実装済み | 間接 | 評価保存でdone |
| 課題編集 | 課題カード | teacher | 実装済み | なし | AssignmentEditor |
| 先生生徒連携 | Students / Assignments | teacher/student | 実装済み | なし | invite code |
| Viewer Mode | Students | teacher | 実装済み | なし | 生徒データ表示 |
| スケジュール | Calendar / SelectionPanel | 全ユーザー | 実装済み | あり | study_plan |
| 逆算スケジュール | AssignmentList / SelectionPanel | 全ユーザー/teacher | 実装済み | 間接 | planAssignmentRemaining, 曜日指定 |
| ランキング | `RankingsApp` | 旧公開機能 | 現在到達困難 | なし | `/rankings` redirect |
| 公開ライブラリ | `LibraryApp` | 旧公開機能 | 現在到達困難 | なし | `/library` redirect |
| EXP | 評価保存/プロフィール | 全ユーザー | 一部実装 | Homeに一部集約なし | RPC側詳細は別途確認必要 |
| 称号 | Titles | 全ユーザー | 実装済み | Progressから | equip可能 |
| Cafe | Cafe | 全ユーザー | UIのみ | あり | Coming Soon |
| 色変更 | Settings | 全ユーザー | 実装済み | 間接 | CSS変数保存 |
| アイコン変更 | Settings | 全ユーザー | 実装済み | Homeから設定 | localStorage |
| データ削除 | Settings | 全ユーザー | 一部実装 | 間接 | 未使用メディア削除 |
| ストレージ確認 | Settings | 全ユーザー | 実装済み | 間接 | local IndexedDB |
| バックアップ | なし | 全ユーザー | 未実装 | なし | `.recaloop`は教材配布であり全体バックアップではない |
| 管理者承認 | `/admin/submissions` | admin | 実装済み | なし | ただし公開UIは現在redirect |
| デッキ作成専用ページ | `/deck-builder` | ログイン不要 | 実装済み | なし | ローカル専用 |

## 11. 未実装・仮実装・到達不能な機能

### TODOコメントがあるもの

- この調査範囲ではTODOコメントの網羅検索は未実施。必要なら別途 `rg TODO` で確認する。

### ダミーデータを使っているもの

- `lib/foundation.ts` の `features`, `notices`, `roadmapItems` はローカル定義
- Cafeは実データではなくComing Soon説明
- HomeのCafe来店数は既存学習データから仮に見せている可能性がある

### 見た目だけ存在するもの

- Cafeのショップ・お客さん・模様替え・ランキング
- Studyのタイマー、ポモドーロ、手動勉強記録、カフェ集中、リスニング
- Progressの目標、模試・テスト、詳細分析

### ボタンはあるが処理がない / Coming Soonになるもの

- `FeatureCard` で `status !== available` の機能
- Coming Soon dialogを表示し、実処理はなし

### ルートはあるが入口がない、またはredirectされるもの

- `/library`
- `/rankings`
- `/share/cards/[token]`
- `/share/material/[token]`
- `/setup`

### コードはあるが現在使用されていないと思われるもの

- `components/library-app.tsx`
- `components/rankings-app.tsx`
- `components/shared-content.tsx`
- `components/app-route-nav.tsx`

### 環境変数や外部サービスがないと動かないもの

- Supabase Auth
- Supabase DBを使う全保存機能
- Admin submissions
- Teacher/student RPC
- Review RPC
- Assignment RPC

## 12. 私が書き換えるための新設計テンプレート

# RecaLoop 新画面設計案

## 共通方針

- デザイン：
- タブ構成：
- メインユーザー：
- Homeの役割：
- Cafeの役割：

## Home

### 残すもの

*

### 削除するもの

*

### 追加するもの

*

### 表示順

```text
Home
├─ 
├─ 
└─ 
```

### 各要素の詳細

#### 要素名

- 内容：
- 表示位置：
- 表示条件：
- タップ時：
- デザイン：
- 優先度：

## Deck

### 残すもの

*

### 削除するもの

*

### 追加するもの

*

### 表示順

```text
Deck
├─ 
├─ 
└─ 
```

### 各要素の詳細

#### 要素名

- 内容：
- 表示位置：
- 表示条件：
- タップ時：
- デザイン：
- 優先度：

## Schedule

### 残すもの

*

### 削除するもの

*

### 追加するもの

*

### 表示順

```text
Schedule
├─ 
├─ 
└─ 
```

### 各要素の詳細

#### 要素名

- 内容：
- 表示位置：
- 表示条件：
- タップ時：
- デザイン：
- 優先度：

## Cafe

### 残すもの

*

### 削除するもの

*

### 追加するもの

*

### 表示順

```text
Cafe
├─ 
├─ 
└─ 
```

### 各要素の詳細

#### 要素名

- 内容：
- 表示位置：
- 表示条件：
- タップ時：
- デザイン：
- 優先度：

## Settings

### 残すもの

*

### 削除するもの

*

### 追加するもの

*

### 表示順

```text
Settings
├─ 
├─ 
└─ 
```

### 各要素の詳細

#### 要素名

- 内容：
- 表示位置：
- 表示条件：
- タップ時：
- デザイン：
- 優先度：

## その他の画面

### 残すもの

*

### 削除するもの

*

### 追加するもの

*

### 表示順

```text
Other
├─ 
├─ 
└─ 
```

### 各要素の詳細

#### 要素名

- 内容：
- 表示位置：
- 表示条件：
- タップ時：
- デザイン：
- 優先度：

## 削除候補

*

## 新規追加候補

*

## 保留

*

