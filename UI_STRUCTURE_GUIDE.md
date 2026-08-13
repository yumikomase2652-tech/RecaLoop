# RecaLoop UI Structure Guide

このファイルは、RecaLoop / Cafeloop UIを今後も保守しやすい形で実装するための基準書です。

役割は2つです。

- 現在のUI構造を把握するためのガイド
- 今後のUI実装・修正時に必ず確認するルール

新しい主要画面、主要コンポーネント、SCSS構成、共通UI、トークン構成を追加・移動・削除した場合は、このファイルも更新してください。細かなclass追加だけで毎回更新する必要はありませんが、画面構造や編集方法に影響する変更では必ず更新します。

## 1. UI実装の基本方針

- 画面固有・コンポーネント固有のスタイルは、原則としてSCSS Modulesで管理します。
- TSXとSCSSは対応関係が分かる配置にします。
- Codexが実装する場合でも、人が後からTSXとSCSSを追える構造を維持します。
- ユーザーが手動で全UIを編集する前提ではなく、必要なときに余白、サイズ、配置、文字、角丸、色、影、アニメーションを直接調整できる状態を維持します。
- 見た目だけのために不要なラッパーコンポーネントを増やしません。
- 過剰な抽象化を避けます。単一画面だけの見た目は、共通コンポーネントのvariantではなく、その画面のclassとSCSSで調整します。
- `globals.css` / 将来の`globals.scss`へページ固有スタイルを増やしすぎません。
- 共通コンポーネントにvariantを追加する場合は、複数箇所で本当に使われるか、既存variantで代用できないかを確認します。
- 新しいUIライブラリは安易に追加しません。

### 現状メモ

現在の実装は、`app/globals.css`とTSX内のclassNameに多くのUIスタイルが残っています。今後の新規UI・大きなUI修正では、以下のようにSCSS Modulesへ段階的に移行します。

```text
components/
  cafe/
    ShopCard.tsx
    ShopCard.module.scss

components/
  study/
    StudyActionGrid.tsx
    StudyActionGrid.module.scss
```

Next.jsで`.module.scss`を使う場合は`sass`依存が必要です。最初にSCSS Modulesへ移行するPRで、依存追加とビルド確認を同時に行ってください。小さな修正で既存の`globals.css`を触る場合も、ページ固有スタイルをさらに増やさない方針を守ります。

## 2. UI編集の基本手順

1. ブラウザの検証ツールで対象要素を確認する
2. class名またはコンポーネント名を確認する
3. VS Code / `rg`でclass名・コンポーネント名を検索する
4. 対応するTSXとCSS / SCSSを確認する
5. 共通コンポーネントの場合は使用画面と影響範囲を確認する
6. 必要なら共通トークンを使う
7. 構造に影響する変更なら、このファイルを更新する

## 3. 全体ディレクトリ構造

UIに関係する主要ファイルは次の通りです。

```text
app/
  globals.css                    # 現在のグローバルCSS、トークン、既存UIスタイル
  layout.tsx                     # ルートレイアウト、PWA登録
  page.tsx                       # ログイン前ランディング
  dashboard/
    layout.tsx                   # 認証チェック
    page.tsx                     # PersonalApp入口
  login/page.tsx                 # 認証画面
  auth/update-password/page.tsx  # パスワード再設定
  deck-builder/page.tsx          # ログイン不要の.recaloop作成ページ
  admin/submissions/page.tsx     # 管理者向け公開申請画面
  share/*/[token]/page.tsx       # 旧共有リンク表示
  ui-lab/page.tsx                # 開発時のみUIラボ

components/
  personal-app.tsx               # 現在の主要アプリ画面の大半
  app-route-nav.tsx              # ルート遷移型ナビ
  nav-icons.tsx                  # タブバー用線画アイコン
  coffee-loader.tsx              # コーヒーカップローディング
  cafe/
    shop-card.tsx                # Home最上部のショップカード
    cafe-preview.tsx             # ショップカード内のCafeプレビュー
    cafe-scene.tsx               # 旧CSS描画のCafeシーン（新Cafeはfeatures/cafeを使用）
  study/
    study-action-grid.tsx        # 2列アクション
    study-action-card.tsx        # 2列カード
    material-gallery-card.tsx    # 教材ギャラリーカード
    material-list-row.tsx        # 教材リスト行
    material-cover.tsx           # 教材カバー
    rating-buttons.tsx           # 評価ボタン
  ui/
    button.tsx
    card.tsx
    list-row.tsx
    page-header.tsx
    bottom-sheet.tsx
    loading-overlay.tsx
    section.tsx
    toggle.tsx
    segmented-control.tsx
    search-field.tsx
    empty-state.tsx
  development/
    ui-lab.tsx
    ui-lab.module.css
    token-control-panel.tsx

features/
  cafe/
    components/
      cafe-scene.tsx             # Cafe Scene共通描画（full / preview / editor）
      cafe.module.css            # Cafe画面固有スタイル
    screens/
      cafe-root.tsx              # Cafe Home / Goods / Shop / Visitors / Album / Gifts / Menu
    data/
      mock-items.ts
      mock-visitors.ts
      mock-themes.ts
      mock-slots.ts
      mock-gifts.ts
      default-state.ts
    hooks/
      use-cafe-state.ts          # Phase 1 localStorage状態管理
    types/
      cafe.ts

lib/
  ui-tokens.ts                   # UIラボ用トークン定義
  foundation.ts                  # Coming Soon / notice / roadmap定義
  recaloop-data.ts               # データ取得・保存
  recaloop-package.ts            # .recaloop入出力
  local-media.ts                 # IndexedDBメディア保存
```

## 4. 画面別対応表

| 画面・部品 | TSXファイル | SCSS/CSSファイル | 主なclass名 | 主な子コンポーネント | 使用する共通UI |
| --- | --- | --- | --- | --- | --- |
| Home | `components/personal-app.tsx` `HomeView` | `app/globals.css` | `ios-screen`, `home-ios`, `home-shop-wrap`, `home-study-actions` | `ShopCard`, `StudyActionCard`, `StudyShareSheet` | `UiSection` |
| Study | `components/personal-app.tsx` `StudyHub` | `app/globals.css` | `study-hub-ios`, `study-lab-screen`, `compact-actions` | `StudyActionGrid`, `StudyActionCard` | `UiSection` |
| Calendar | `components/personal-app.tsx` `CalendarView` | `app/globals.css` | `calendar-titlebar`, `calendar-month`, `calendar-month-grid`, `calendar-actions` | `SelectableTargetTree`, `DateInput` | bottom sheet風UI |
| Summary | `components/personal-app.tsx` `ProgressHubFixed` | `app/globals.css` | `summary-screen`, `summary-section`, `summary-metrics`, `summary-placeholder` | `Metric`, `LearningHeatmap` | なし |
| Cafe | `components/personal-app.tsx` `CafeHub`, `features/cafe/screens/cafe-root.tsx` | `features/cafe/components/cafe.module.css` | `root`, `screenShell`, `sceneFrame`, `quickStrip`, `itemGrid` | `CafeScene`, `useCafeState` | なし |
| Settings | `components/personal-app.tsx` `SettingsView` | `app/globals.css` | `settings-ios`, `settings-group`, `settings-group-card`, `settings-top-row`, `settings-form-row` | `SettingsGroup`, `SettingsNavRow`, `ThemePresetPicker`, `ThemeColorPicker`, `LocalStoragePanel` | なし |
| Notifications | `components/personal-app.tsx` `NoticesView` and `SettingsNotices` | `app/globals.css` | `notices-screen`, `notice-list`, `settings-notice-list`, `roadmap-panel` | `PageTitle`, `SettingsGroup` | なし |
| 教材一覧 | `components/personal-app.tsx` `DeckList` | `app/globals.css` | `materials-ios`, `materials-nav`, `materials-compact-toolbar`, `material-gallery-production`, `deck-list-ios` | bottom sheet, `BookOpen` icon | なし |
| 復習画面 | `components/personal-app.tsx` `ReviewView` | `app/globals.css` | `review-hero`, `rating-grid`, `check-toggle` | `RatingEditor`, `SelectableTargetTree` | なし |
| 予定に取り組む画面 | `components/personal-app.tsx` study session state | `app/globals.css` | `study-context`, `rating-grid`, `check-toggle` | `RatingEditor`, media viewer | なし |
| タイマー画面 | `components/personal-app.tsx` `StudyHub`から遷移する`study` view | `app/globals.css` | `study-hub-ios`, `lab-study-action-grid` | `StudyActionGrid` | `UiSection` |
| ログイン | `app/login/page.tsx` | `app/globals.css` | `auth-page`, `auth-panel`, `brand`, `field` | Supabase Auth | なし |
| 初回設定 | `components/personal-app.tsx` `OnboardingModal` | `app/globals.css` | `onboarding-backdrop`, `onboarding-panel`, `select-field` | `SchoolPicker` | なし |
| .recaloop作成 | `app/deck-builder/page.tsx` | Tailwind className中心 | `min-h-screen`, `rounded-3xl`など | `createStoredZipStable` | なし |
| UI Lab | `components/development/ui-lab.tsx` | `components/development/ui-lab.module.css` + `globals.css` | `lab-*` | `TokenControlPanel` | `components/ui/*`, `components/study/*`, `components/cafe/*` |

## 5. 主要画面のコンポーネントツリー

### Home

```text
PersonalApp
└─ HomeView
   ├─ UiSection
   │  └─ home-shop-wrap
   │     ├─ ShopCard
   │     │  ├─ lab-shop-profile
   │     │  ├─ lab-shop-divider
   │     │  ├─ lab-shop-records
   │     │  ├─ lab-shop-divider
   │     │  └─ CafePreview
   │     │     └─ CafeScene
   │     └─ home-share-button
   ├─ UiSection
   │  └─ home-study-actions
   │     ├─ StudyActionCard 今日の予定
   │     ├─ StudyActionCard 今日の復習
   │     ├─ StudyActionCard タイマー
   │     └─ StudyActionCard 教材一覧
   └─ StudyShareSheet
```

### Study

```text
PersonalApp
└─ StudyHub
   ├─ UiSection
   │  └─ StudyActionGrid
   │     ├─ StudyActionCard 予定に取り組む
   │     ├─ StudyActionCard 復習する
   │     ├─ StudyActionCard 教材
   │     └─ StudyActionCard タイマー
   └─ UiSection
      └─ compact-actions
         ├─ StudyActionCard 教材一覧
         └─ StudyActionCard リスニング
```

### Summary

```text
PersonalApp
└─ ProgressHubFixed
   ├─ summary-section 今日
   │  └─ Metric x 6
   ├─ summary-section 学習推移
   │  └─ LearningHeatmap
   ├─ summary-section 教材分析
   ├─ summary-section 学校のテスト結果
   ├─ summary-section 目標・テストまで
   ├─ summary-section 復習分析
   ├─ summary-section 苦手分析
   └─ summary-section モチベーション
```

### Cafe

```text
PersonalApp
└─ CafeHub
   └─ CafeRoot
      ├─ CafeHomeScreen
      │  ├─ CafeScene mode="full"
      │  ├─ summaryGrid
      │  └─ navGrid
      ├─ GoodsScreen
      │  ├─ CafeScene mode="editor"
      │  └─ owned item picker
      ├─ ShopScreen
      ├─ VisitorsScreen
      ├─ AlbumScreen
      ├─ GiftsScreen
      └─ MenuScreen
```

## 6. 共通コンポーネント一覧

| コンポーネント | TSX | SCSS/CSS | 使用画面 | 用途 | 変更時の影響 |
| --- | --- | --- | --- | --- | --- |
| `UiButton` | `components/ui/button.tsx` | `app/globals.css` `lab-button*` | UI Lab中心 | 汎用ボタン | `lab-button*`利用箇所すべて |
| `UiCard` | `components/ui/card.tsx` | `app/globals.css` `lab-card` | UI Lab中心 | 汎用カード | UI Lab / 今後の共通カード |
| `UiListRow` | `components/ui/list-row.tsx` | `app/globals.css` `lab-list-*` | UI Lab中心 | iOS風リスト行 | リストUI全般 |
| `UiPageHeader` | `components/ui/page-header.tsx` | `app/globals.css` `lab-page-header*` | UI Lab中心 | ページヘッダー | 共通ヘッダー化する場合に影響 |
| `UiBottomSheet` | `components/ui/bottom-sheet.tsx` | `app/globals.css` `lab-bottom-sheet*` | UI Lab中心 | ボトムシート | 選択系モーダル共通化時に影響 |
| `UiLoadingOverlay` | `components/ui/loading-overlay.tsx` | `app/globals.css` `lab-loading-overlay` | UI Lab中心 | ローディング | ローディングUI |
| `UiSection` | `components/ui/section.tsx` | `app/globals.css` `lab-section*` | Home / Study | セクション | Home/Studyの余白 |
| `UiToggle` | `components/ui/toggle.tsx` | `app/globals.css` `lab-toggle` | UI Lab中心 | スイッチ | 設定UIへ適用時に影響 |
| `UiSegmentedControl` | `components/ui/segmented-control.tsx` | `app/globals.css` `lab-segmented` | UI Lab中心 | セグメント | 表示切替UI |
| `ShopCard` | `components/cafe/shop-card.tsx` | `app/globals.css` `lab-shop-*` | Home | ショップカード | Home最上部、プロフィール導線 |
| `CafePreview` | `components/cafe/cafe-preview.tsx` | `features/cafe/components/cafe.module.css` | ShopCard | Cafe入口プレビュー | HomeのCafeビジュアル |
| `CafeScene` | `features/cafe/components/cafe-scene.tsx` | `features/cafe/components/cafe.module.css` | Home ShopCard / Cafe / Goods | Cafeレイヤー描画 | Cafe画面とHomeプレビュー |
| `StudyActionGrid` | `components/study/study-action-grid.tsx` | `app/globals.css` `lab-study-action-grid` | Home / Study | 2列アクション | Home/Studyの主操作 |
| `StudyActionCard` | `components/study/study-action-card.tsx` | `app/globals.css` `lab-study-action*` | Home / Study | アクションカード | 2列カード全般 |
| `MaterialGalleryCard` | `components/study/material-gallery-card.tsx` | `app/globals.css` `lab-material-gallery-card` | UI Lab / 将来教材 | 教材ギャラリー | 教材カード |
| `MaterialListRow` | `components/study/material-list-row.tsx` | `app/globals.css` `lab-material-list-row` | UI Lab / 将来教材 | 教材リスト行 | 教材リスト |
| `CoffeeLoader` | `components/coffee-loader.tsx` | `app/globals.css` `coffee-*` | App loading | コーヒーカップローダー | 全体ローディング |
| `BottomNav` | `components/personal-app.tsx` | `app/globals.css` `bottom-nav`, `nav-*` | Dashboard | 下部タブバー | 主要ナビ全体 |

## 7. SCSS / CSSトークン一覧

現状は`app/globals.css`のCSSカスタムプロパティと`lib/ui-tokens.ts`のUIラボ用トークンが併存しています。

| 変数名 | 用途 | 主な使用場所 |
| --- | --- | --- |
| `--ink` | 旧テキスト色 | 旧カード、旧UI |
| `--muted` | 補助文字色 | 旧カード、補足文 |
| `--brand` | 旧メイン色 | ボタン、旧ナビ |
| `--brand-dark` | 旧濃色 | hover、旧CTA |
| `--accent` | 旧アクセント背景 | アイコン背景、チップ |
| `--line` | 旧線色 | border、separator |
| `--bg` | 旧背景 | body、app |
| `--canvas` | 全体背景 | html/body |
| `--danger` | 旧destructive色 | danger系 |
| `--reward` | 称号・報酬色 | title/card |
| `--color-text` | 新UIの文字色 | iOS/Cafeloop UI |
| `--color-accent` | 新UIのアクセント | 2列カード、タブ選択 |
| `--color-base` | 新UIの背景 | app/page |
| `--color-surface` | 新UIのsurface | Settings/ShopCard |
| `--color-border` | 新UIのseparator | Settings/list/card |

`lib/ui-tokens.ts`には、UIラボで使うサイズ、余白、角丸、影、動き、プリセットが定義されています。実画面へ反映する場合は、`globals.css`の直接値と二重管理にならないよう注意します。

## 8. よく変更する項目の場所

| 変更したいもの | まず見る場所 |
| --- | --- |
| ページ全体の左右余白 | `components/personal-app.tsx`の`app-page`内wrapper、`app/globals.css`の`.app-page` / `.ios-screen` |
| カードの角丸 | `app/globals.css`の`.surface`, `.card`, `.lab-shop-card`, `.ios-menu-card`, `.settings-group-card` |
| ボタンの高さ | `app/globals.css`の`.primary-button`, `.secondary-button`, `.save-button`, `.lab-button*` |
| ボタン間の余白 | 各画面class、特に`.home-study-actions`, `.settings-button-row`, `.calendar-actions` |
| 文字サイズ | `app/globals.css`の画面別class、`body`フォント指定 |
| 補助文字色 | `--muted`, `--color-text`の`color-mix`指定 |
| 下部タブバー | `components/personal-app.tsx` `BottomNav`, `components/nav-icons.tsx`, `app/globals.css` `.bottom-nav`, `.nav-icon-wrap`, `.nav-badge` |
| ShopCard | `components/cafe/shop-card.tsx`, `app/globals.css` `.lab-shop-*` |
| ローディング表示 | `components/coffee-loader.tsx`, `components/ui/loading-overlay.tsx`, `app/globals.css` `.coffee-*`, `.loading-overlay` |
| Safe Area | `app/globals.css` `.bottom-nav`, `.viewer-banner`, `env(safe-area-inset-*)` |
| モーダル / ボトムシート | `components/ui/bottom-sheet.tsx`, `components/personal-app.tsx`内の`bottom-sheet-backdrop`, `stats-dialog-backdrop` |
| カフェテーマ | `components/personal-app.tsx` `SettingsView`, `ThemePresetPicker`, `ThemeColorPicker`, `applyTheme` |
| テーマカラー | `lib/ui-tokens.ts`, `components/personal-app.tsx`のtheme presets/options |
| 共通背景 | `app/globals.css` `body`, `.app-page`, `--color-base` |
| 共通セパレーター | `--line`, `--color-border`, `.settings-group-card`, `.settings-row`, `.lab-shop-divider` |

## 9. 新規UI追加時のチェックリスト

- [ ] TSXとSCSS Moduleの対応が分かるか
- [ ] class名から画面上の役割が分かるか
- [ ] `globals.css`へページ固有スタイルを書いていないか
- [ ] 既存コンポーネントで適切に対応できるか
- [ ] 単一画面のためだけに共通variantを増やしていないか
- [ ] 見た目だけのラッパーを増やしすぎていないか
- [ ] Safe Areaを確認したか
- [ ] 320px / 375px / 390px / 430px / 768px / PC幅で崩れないか
- [ ] タップ領域は原則44px以上か
- [ ] ローディング、空状態、エラー状態があるか
- [ ] UI_STRUCTURE_GUIDE.mdの更新が必要か確認したか

## 10. 実装ルール詳細

### SCSS Modulesを基本とする

今後の画面固有・コンポーネント固有スタイルは、次のように対応させます。

```text
ShopCard.tsx
ShopCard.module.scss
```

または、

```text
ShopCard/
  ShopCard.tsx
  ShopCard.module.scss
```

TSXを開いたとき、画面上の表示順と構造が分かるようにします。

```tsx
<section className={styles.shopCard}>
  <div className={styles.profileArea}>...</div>
  <div className={styles.studyStats}>...</div>
</section>
```

### class名

良い例:

```scss
.shopCard {}
.profileArea {}
.studyStats {}
.primaryAction {}
.sectionTitle {}
```

避ける例:

```scss
.box1 {}
.wrapper2 {}
.left {}
.bigText {}
.blueButton {}
```

### Tailwind / inline styleを残してよい例外

- 実行時に値が変わるstyle
- CSS変数へ渡す値
- 位置や大きさを計算結果から設定する必要がある場合
- 外部ライブラリの仕様上必要な場合
- 既存画面で移行リスクが高く、別作業で段階移行する場合

例外を使う場合は、コードまたはこのガイドで理由が分かるようにします。

## 11. 既存ドキュメントとの役割分担

- `SCREEN_DESIGN_CURRENT.md`: 現状画面構成・機能・遷移の棚卸し
- `UI_STRUCTURE_GUIDE.md`: UI実装ルール、ファイル対応、編集場所、構造維持ルール
- `docs/cafeloop-foundation-audit.md`: Cafeloop基盤調査・初期整理メモ
- `README.md`: セットアップ、機能概要、DB/CSV/.recaloop仕様

将来`UI_COMPONENT_CATALOG.md`を作る場合は、各UIコンポーネントのprops、variant、使用例をそちらに分離し、このガイドからリンクします。

## 12. 今後の移行メモ

すぐに全CSSをSCSS Modulesへ移す必要はありません。優先順位は次の通りです。

1. `components/cafe/shop-card.tsx`の`.lab-shop-*`
2. `components/study/study-action-grid.tsx` / `study-action-card.tsx`の`.lab-study-*`
3. `SettingsView`周辺の`.settings-*`
4. 教材一覧 / デッキ詳細の`.materials-*`, `.deck-*`
5. Calendar / Summary / Cafeの画面固有class
6. `components/ui/*`の`lab-*`
7. 最後に`globals.css`からページ固有スタイルを削除

機能変更、Supabase処理、データ取得、ルーティング変更とは分けて進めます。
