# RecaLoop UI Component Catalog

作成日：2026-07-17  
目的：既存機能を壊さずにUI再設計を進めるため、現在のUIと今後必要な共通UIを整理する。

## 方針

- Cafe以外は、一般的で洗練された学習アプリUIとして扱う。
- Cafe要素はHome上部のショップカードとCafe画面に閉じ込める。
- 通常UIの色設定とCafeテーマは分離する。
- 既存の保存処理・Supabase・復習・課題・Viewer Modeには触れない。
- 新規UIパーツは `components/personal-app.tsx` に追加せず、`components/ui`、`components/study`、`components/cafe`、`components/development` に分ける。
- 最終値はUIラボで調整し、確定後にトークンへ反映する。

## A. レイアウト・画面構造

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| App Screen | 画面全体の余白と背景 | 全画面 | `.app-page`, `.ios-screen` | 必要 | 高 | padding, background, max-width |
| Scroll Container | 縦スクロール領域 | 全画面 | 画面ごと直接 | 必要 | 中 | padding-bottom, safe area |
| Safe Area Container | iPhone下部/上部回避 | 全画面 | CSSで部分対応 | 必要 | 高 | safe-area inset |
| Page Header | 通常ページ見出し | 教材, 設定, カレンダー | `PageTitle`, `ios-page-nav` | 必要 | 高 | height, title size, back size |
| Navigation Bar | 上部操作列 | Home, Study | `AppTopBar` | 必要 | 中 | icon size, spacing |
| Large Title Header | 大きな見出し | 将来の一覧画面 | 旧見出し混在 | 必要 | 中 | title size, margin |
| Compact Header | 小さい見出し | 詳細・学習 | `PageTitle` | 必要 | 高 | height, label size |
| Bottom Tab Bar | 下部5タブ | メインアプリ | `BottomNav`, `AppRouteNav` | 必要 | 高 | height, blur, icon size |
| Tab Bar Item | タブ項目 | メインアプリ | `BottomNav`内直接 | 必要 | 高 | active color, label size |
| Page Section | セクションまとまり | Home, Study, Settings | `.ios-section`, `.surface` | 必要 | 高 | section gap |
| Section Header | セクション見出し | Home, Study | `.ios-section-header` | 必要 | 中 | font, spacing |
| Section Footer | 補足説明 | 設定・フォーム | 画面ごと直接 | 必要 | 中 | caption size |
| Divider | 区切り線 | 設定, Shop Card | 複数class | 必要 | 高 | opacity, thickness |
| Spacer | 余白 | 全画面 | CSS直指定 | 必要 | 中 | height scale |
| Sticky Area | 固定操作領域 | Deck Builder, 学習 | 画面ごと直接 | 必要 | 中 | top/bottom offset |
| Bottom Action Area | 下部CTA | 学習・モーダル | 画面ごと直接 | 必要 | 高 | height, safe area |
| Two Column Grid | 2列ボタン | Home, Study | `.home-today-actions`, `.quick-grid` | 必要 | 高 | gap, card height |
| Gallery Grid | 教材ギャラリー | Study/教材 | 未統一 | 必要 | 高 | columns, gap, cover ratio |
| List Container | リスト全体 | 教材, 設定 | `.ios-list`, settings group | 必要 | 高 | radius, separator |
| Grouped List | iOS設定風リスト | 設定 | `SettingsGroup` | 必要 | 高 | row height, separator |
| Empty State Layout | 空状態 | 各画面 | `.empty-state`, 直接実装 | 必要 | 中 | icon size, text size |
| Loading Layout | ローディング | 初期ロード | `CoffeeLoader` | 必要 | 中 | overlay, animation |
| Error Layout | エラー表示 | 初期ロード, import | notice等 | 必要 | 中 | tone, spacing |

## B. ボタン・操作部品

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Primary Button | 主操作 | 全画面 | `.primary-button` | 必要 | 高 | height, radius, padding |
| Secondary Button | 副操作 | 全画面 | `.secondary-button` | 必要 | 高 | height, border |
| Tertiary Button | 控えめ操作 | 全画面 | `.quiet-button` | 必要 | 中 | opacity, text color |
| Destructive Button | 削除/解除 | 設定, デッキ, 課題 | `.danger-button`, confirm | 必要 | 高 | danger color |
| Text Button | テキストリンク | 設定, リスト | 直接実装 | 必要 | 中 | font weight |
| Icon Button | アイコン単独 | Header, Lists | `.ios-icon-button` | 必要 | 高 | touch size, icon size |
| Back Button | 戻る | Page Header | `PageTitle`内直接 | 必要 | 高 | size, hit area |
| Close Button | 閉じる | Dialog, Overlay | `.dialog-close` | 必要 | 高 | position, size |
| Add Button | 追加 | 教材 | `Plus`ボタン直接 | 必要 | 高 | size, shape |
| Floating Action Button | 浮遊追加 | 将来 | 未実装 | 任意 | 低 | size, shadow |
| Full Width Button | 横幅いっぱい | Sheet, Form | class直指定 | 必要 | 高 | width, height |
| Compact Button | 小ボタン | リスト操作 | 直接実装 | 必要 | 中 | compact height |
| Two Column Action Card | 2列学習CTA | Home, Study | 個別実装 | 必要 | 高 | height, number size |
| Menu Button | メニュー | リスト | ellipsis直接 | 必要 | 中 | icon size |
| Overflow Button | ...操作 | Deck row | `.ios-ellipsis` | 必要 | 高 | touch size |
| Segmented Control | 表示切替 | 教材 | 未統一 | 必要 | 中 | segment height |
| Tab Switcher | タブ切替 | 将来 | 未統一 | 任意 | 低 | active bg |
| Toggle | ON/OFF | 設定 | select/checkbox混在 | 必要 | 高 | width, knob size |
| Checkbox | 複数選択 | デッキ, 課題 | 複数実装 | 必要 | 高 | checked state |
| Radio Button | 単一選択 | 未定 | 未実装 | 任意 | 低 | size |
| Stepper | 数値調整 | UI Lab | 未実装 | 必要 | 中 | size |
| Slider | token調整 | UI Lab | 未実装 | 必要 | 高 | track height |
| Context Menu Trigger | 操作メニュー | 教材 | ellipsis | 必要 | 中 | hit area |

## C. カード

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Standard Card | 標準カード | 全画面 | `.surface`, `.card` | 必要 | 高 | radius, padding, border |
| Action Card | タップ可能カード | Home, Study | 複数 | 必要 | 高 | pressed opacity |
| Two Column Action Card | 2列アクション | Home, Study | 個別 | 必要 | 高 | height, numeric size |
| Shop Card | Home上部 | Home | `home-shop-card` | 必要 | 高 | height, preview ratio |
| Feature Card | Coming Soon | Study, Cafe | `FeatureCard` | 必要 | 中 | status label |
| Summary Card | 統計 | Summary | `home-mini-stats` | 必要 | 中 | metric layout |
| Statistic Card | 数値カード | Summary | 直接 | 必要 | 中 | number size |
| Progress Card | 進捗 | Home, Deck | 複数 | 必要 | 中 | progress height |
| Notice Card | お知らせ | Notices | 直接 | 必要 | 低 | icon size |
| Warning Card | 警告 | Import, Admin | notice | 必要 | 中 | color |
| Error Card | エラー | Import, Load | notice | 必要 | 中 | color |
| Empty State Card | 空状態 | 全画面 | 複数 | 必要 | 中 | min height |
| Profile Card | 設定 | Settings | `settings-profile-card` | 必要 | 中 | avatar size |
| Material Gallery Card | 教材ギャラリー | Study/教材 | 未統一 | 必要 | 高 | cover ratio |
| Material List Card | 教材リスト | Study/教材 | DeckList row | 必要 | 高 | row height |
| Folder List Row | フォルダ | 教材 | tree直接 | 必要 | 高 | indent, disclosure |
| Assignment Card | 課題 | Assignments | `AssignmentCard` | 必要 | 中 | density |
| Schedule Card | 予定 | Calendar | 直接 | 必要 | 中 | date layout |
| Achievement Card | 称号 | Titles | `title-card` | 必要 | 低 | medal size |
| Cafe Item Card | Cafe | Cafe | 未実装 | 将来 | 低 | item image |

## D. 教材関連

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Material Cover | 表紙 | 教材ギャラリー | 未統一 | 必要 | 高 | aspect ratio |
| Material Thumbnail | 小サムネ | リスト | 未統一 | 必要 | 高 | size |
| Material Gallery Card | ギャラリー行 | 教材 | 未統一 | 必要 | 高 | columns |
| Material List Row | 教材リスト | 教材 | DeckList row | 必要 | 高 | row padding |
| Folder Row | 階層行 | デッキ詳細 | tree直接 | 必要 | 高 | depth indent |
| Folder Header | セクション見出し | デッキ詳細 | folder card | 必要 | 中 | disclosure |
| Material Progress | 進捗表示 | 教材 | 直接 | 必要 | 中 | bar height |
| Material Metadata | 件数/期限 | 教材 | 直接 | 必要 | 中 | caption |
| Search Bar | 検索 | 教材 | `.ios-search` | 必要 | 高 | height |
| Sort Button | 並び替え | 教材 | select | 必要 | 中 | compact |
| List/Gallery View Switcher | 表示切替 | 教材 | 未実装 | 必要 | 中 | segmented |
| Material Add Button | 追加 | 教材 | plus | 必要 | 高 | touch target |
| Material More Menu | その他 | 教材 | ellipsis | 必要 | 中 | menu |
| Hierarchy Row | 階層表示 | デッキ詳細 | tree直接 | 必要 | 高 | indent |
| Expand/Collapse Button | 開閉 | デッキ詳細 | `details` | 必要 | 高 | indicator |
| Selection Checkbox | 選択 | デッキ詳細 | 複数 | 必要 | 高 | visual state |
| Breadcrumb | パンくず | 学習 | 直接 | 必要 | 高 | separator |
| Card/Problem Row | 問題行 | デッキ詳細 | MaterialItem/WordCardRow | 必要 | 高 | row height |
| Rating Editor | 評価 | 学習/復習 | `RatingEditor` | 必要 | 高 | button sizes |
| Batch Action Bar | 一括操作 | 選択 | `SelectionPanel` | 必要 | 中 | sticky |

## E. Home・Study共通学習アクション

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| 予定に取り組む | 今日の予定CTA | Home, Study | Home専用ボタン | 必要 | 最高 | height, number size |
| 復習する | 今日の復習CTA | Home, Study | Home/Study個別 | 必要 | 最高 | icon, count |
| 最後に取り組んだ教材 | 続きから | Home, Study | Home最近教材とは別 | 必要 | 最高 | empty state |
| タイマー | タイマー入口 | Home, Study | FeatureCard | 必要 | 高 | no count layout |

共通レイアウト条件：

- 2列×2段
- 左上アイコン
- 右上に件数または進捗
- 左下に名称
- カード全体がタップ可能
- 0件・999件・長い教材名に対応

## F. フォーム

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Text Field | 単一入力 | 設定, 作成 | `.field` | 必要 | 高 | height |
| Search Field | 検索 | 教材 | `.ios-search` | 必要 | 高 | icon size |
| Text Area | 長文 | Deck Builder | 直接 | 必要 | 中 | min height |
| Select | 選択 | 設定 | select直接 | 必要 | 高 | height |
| Date Picker | 日付 | 課題, 計画 | `DateInput` | 必要 | 高 | width |
| Time Picker | 時刻 | 将来 | 未実装 | 任意 | 低 | height |
| Color Picker | 色 | 設定 | `ThemeColorPicker` | 必要 | 中 | swatch size |
| Image Picker | 画像 | 設定, 将来教材 | local file input | 必要 | 中 | preview |
| File Picker | import | 教材, Deck Builder | label + input | 必要 | 中 | drop area |
| Form Row | iOS設定行 | 設定 | `SettingsFormRow` | 必要 | 高 | row height |
| Form Group | grouped list | 設定 | `SettingsGroup` | 必要 | 高 | group radius |
| Inline Validation | 入力エラー | 設定/Login | 直接 | 必要 | 中 | message size |
| Error Message | エラー | 全画面 | notice | 必要 | 中 | color |
| Help Text | 補足 | フォーム | 直接 | 必要 | 中 | caption |

## G. フィードバック

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Toast | 完了通知 | 全画面 | `PersonalApp` state | 必要 | 中 | duration |
| Alert | 注意 | 削除等 | `confirm` | 必要 | 中 | width |
| Confirmation Dialog | 確認 | 削除/更新 | `confirm`中心 | 必要 | 高 | button layout |
| Modal | 入力/CSV | CSV | `CsvDialog` | 必要 | 中 | width |
| Bottom Sheet | 選択操作 | 教材 | DeckListのみ | 必要 | 高 | radius |
| Action Sheet | 操作一覧 | 教材 | bottom sheet | 必要 | 中 | row height |
| Popover | 補助 | 未実装 | 未実装 | 任意 | 低 | width |
| Loading Overlay | 画面ロード | 初期ロード | CoffeeLoader | 必要 | 中 | delay |
| Inline Loader | ボタン内 | import | 直接 | 必要 | 高 | spinner size |
| Progress Indicator | import | 教材 | 直接 | 必要 | 高 | bar height |
| Skeleton | 読み込み | 未実装 | 未実装 | 任意 | 低 | shimmer |
| Success State | 成功 | import | message | 必要 | 中 | tone |
| Error State | エラー | 全画面 | notice | 必要 | 中 | tone |
| Empty State | 空状態 | 全画面 | 複数 | 必要 | 中 | min height |
| Badge | 件数 | nav/cards | nav-badge/tag | 必要 | 高 | size |
| Notification Dot | 通知点 | nav | 未統一 | 必要 | 中 | size |

## H. 学習画面

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Study Header | 学習上部 | 学習 | 直接 | 必要 | 高 | height |
| Study Progress | 進捗 | 学習 | 直接 | 必要 | 高 | progress height |
| Breadcrumb | 現在位置 | 学習 | 直接 | 必要 | 高 | font size |
| Question Number | 問題番号 | 学習 | 直接 | 必要 | 高 | number size |
| Front Content Area | 表面 | 学習 | 直接 | 必要 | 高 | padding |
| Back Content Area | 裏面 | 学習 | 直接 | 必要 | 高 | padding |
| Media Viewer | 画像/音声表示 | 学習 | 直接 + local media | 必要 | 高 | max height |
| Audio Control | 音声 | 学習 | 直接 | 必要 | 中 | height |
| Reveal Answer Button | 裏面表示 | 学習 | 直接 | 必要 | 高 | bottom position |
| Four Rating Buttons | 評価 | 学習 | `RatingEditor`系 | 必要 | 高 | button grid |
| Skip Button | スキップ | 学習 | 直接 | 必要 | 中 | placement |
| Content On/Off Control | 内容表示切替 | 学習 | 直接 | 必要 | 中 | toggle size |
| Study Session Complete State | 完了 | 学習 | 直接 | 必要 | 中 | illustration |
| Image Zoom Overlay | 画像拡大 | 学習 | `ImageZoomOverlay` | 必要 | 中 | initial fit |

## I. Calendar・Summary

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Calendar Header | 月見出し | Calendar | 直接 | 必要 | 中 | height |
| Month Switcher | 月切替 | Calendar | button | 必要 | 中 | button size |
| Calendar Grid | 月間表示 | Calendar | `calendar-month-grid` | 必要 | 中 | cell size |
| Calendar Day Cell | 日セル | Calendar | 直接 | 必要 | 中 | count position |
| Event Count Indicator | 予定数 | Calendar | b表示 | 必要 | 中 | badge size |
| Schedule List | 日付詳細 | Calendar | SelectableTargetTree | 必要 | 中 | row height |
| Summary Metric | 指標 | Summary | home-mini-stats | 必要 | 中 | number size |
| Heatmap | 継続 | Progress | LearningHeatmap | 必要 | 中 | square size |
| Chart Container | グラフ | 未実装 | 未実装 | 任意 | 低 | height |
| Ranking Row | ランキング | 旧RankingApp | 到達困難 | 任意 | 低 | row density |
| Achievement List | 称号 | Titles | title-card | 必要 | 低 | medal size |

## J. Cafe専用

| パーツ名 | 用途 | 使用予定画面 | 現在の実装 | 新規作成の要否 | 共通化優先度 | 調整対象パラメータ |
| --- | --- | --- | --- | --- | --- | --- |
| Cafe Scene | Cafe内部 | Home, Cafe | CSS装飾 | 必要 | 高 | preview height |
| Cafe Preview | Homeカード内 | Home | `home-cafe-scene` | 必要 | 高 | ratio |
| Shop Card Cafe Illustration | ショップカード下部 | Home | CSS装飾 | 必要 | 高 | height |
| Theme Selector | Cafeテーマ | Cafe/Settings将来 | 未実装 | 将来 | 低 | theme |
| Furniture Item | 家具 | Cafe | 未実装 | 将来 | 低 | item size |
| Interior Item | 内装 | Cafe | 未実装 | 将来 | 低 | item size |
| Shop Item | ショップ商品 | Cafe | 未実装 | 将来 | 低 | price |
| Currency Display | 通貨 | Cafe | 未実装 | 将来 | 低 | icon |
| EXP Display | EXP | Home/Progress | 一部 | 必要 | 中 | number |
| Level Display | レベル | Home/Progress | 一部 | 必要 | 中 | badge |
| Visitor Character | お客さん | Cafe | 未実装 | 将来 | 低 | character size |
| Speech Bubble | 吹き出し | Cafe | 未実装 | 将来 | 低 | bubble |
| Reward Dialog | 報酬 | Cafe | 未実装 | 将来 | 低 | animation |

## アイコン方針

| 用途 | lucide候補 |
| --- | --- |
| 予定 | `CalendarDays` |
| 復習 | `RotateCcw` |
| 最後の教材 | `BookOpen` |
| タイマー | `Timer` |
| 検索 | `Search` |
| 並べ替え | `ArrowUpDown` |
| リスト表示 | `List` |
| ギャラリー表示 | `Grid2X2` |
| 追加 | `Plus` |
| その他 | `Ellipsis` |
| 戻る | `ChevronLeft` |
| 進む | `ChevronRight` |
| 設定 | `Settings` |
| お知らせ | `Bell` |
| Cafe | `Coffee` |

Cafe専用イラストと通常UIアイコンは混ぜない。

