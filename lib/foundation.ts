import type { ReactNode } from "react";

export type FeatureStatus = "available" | "development" | "soon" | "native" | "future";
export type FeatureCategory = "home" | "study" | "materials" | "progress" | "cafe" | "native";

export type FeatureDefinition = {
  id: string;
  title: string;
  description: string;
  status: FeatureStatus;
  category: FeatureCategory;
  action?: "reviews" | "decks" | "calendar" | "assignments" | "students" | "titles" | "settings";
};

export type NoticeCategory = "アップデート" | "お知らせ" | "メンテナンス" | "今後の展開";
export type RoadmapStatus = "構想中" | "デザイン中" | "開発中" | "テスト中" | "公開済み";

export type NoticeItem = {
  category: NoticeCategory;
  date: string;
  title: string;
  body: string;
};

export type RoadmapItem = {
  phase: "早期導入" | "次の段階" | "ネイティブアプリ化後";
  title: string;
  status: RoadmapStatus;
};

export const statusLabels: Record<FeatureStatus, string> = {
  available: "利用できます",
  development: "開発中",
  soon: "COMING SOON",
  native: "ネイティブ版で追加予定",
  future: "今後の構想",
};

export const features: FeatureDefinition[] = [
  { id: "solve", title: "問題を解く", description: "既存のデッキ学習・4段階評価・復習予定作成につながる入口です。", status: "available", category: "study", action: "decks" },
  { id: "reviews", title: "今日の復習", description: "期限が来た問題をまとめて復習できます。", status: "available", category: "home", action: "reviews" },
  { id: "assignments", title: "今日の課題", description: "先生から配布された課題を確認します。", status: "available", category: "home", action: "assignments" },
  { id: "continue", title: "続きから学習", description: "今日の予定や最近開いたデッキから学習を再開します。", status: "development", category: "home" },
  { id: "manual-study", title: "勉強時間をあとから記録", description: "終わった勉強時間を手動で記録する機能です。", status: "development", category: "study" },
  { id: "digital-timer", title: "デジタルタイマー", description: "教材を選び、集中時間を計測するタイマーです。", status: "development", category: "study" },
  { id: "pomodoro", title: "ポモドーロ", description: "集中と休憩を繰り返す学習タイマーです。", status: "development", category: "study" },
  { id: "analog-timer", title: "アナログタイマー", description: "視覚的に残り時間が分かるタイマーです。", status: "soon", category: "study" },
  { id: "cafe-focus", title: "カフェ集中", description: "集中時間に合わせてカフェの一日が進むモードです。", status: "soon", category: "study" },
  { id: "listening", title: "リスニング", description: "音声教材の再生・区間リピートを想定しています。", status: "future", category: "study" },
  { id: "my-materials", title: "マイ教材", description: "既存のデッキ一覧・作成・CSV/.recaloopインポートを使います。", status: "available", category: "materials", action: "decks" },
  { id: "built-in-materials", title: "内蔵教材", description: "公式・サンプル教材を入れられる場所です。", status: "soon", category: "materials" },
  { id: "favorites", title: "お気に入り", description: "よく使う教材をまとめる機能です。", status: "future", category: "materials" },
  { id: "discover-materials", title: "教材を探す", description: "公開教材や公式配布ファイルを探す導線です。", status: "future", category: "materials" },
  { id: "goals", title: "目標", description: "期間・時間・問題数の目標を管理する機能です。", status: "development", category: "progress" },
  { id: "study-time", title: "学習時間", description: "自動セッションと手動記録を集計します。", status: "development", category: "progress" },
  { id: "tests", title: "模試・テスト", description: "テスト結果を保存し、後から推移を見られるようにします。", status: "development", category: "progress" },
  { id: "analytics", title: "詳細分析", description: "教材構造・復習間隔・正誤ログを使った分析です。", status: "future", category: "progress" },
  { id: "my-cafe", title: "マイカフェ", description: "学習EXPがカフェ人気度につながる予定です。", status: "soon", category: "cafe" },
  { id: "customers", title: "お客さん", description: "学習の積み重ねで来店するお客さんを増やす構想です。", status: "soon", category: "cafe" },
  { id: "interior", title: "模様替え", description: "家具・背景・小物を集めてカフェを整える機能です。", status: "future", category: "cafe" },
  { id: "shop", title: "ショップ", description: "獲得アイテムやテーマの交換場所です。", status: "future", category: "cafe" },
  { id: "cafe-ranking", title: "カフェランキング", description: "実データが整ってから追加予定です。偽ランキングは表示しません。", status: "future", category: "cafe" },
  { id: "haptics", title: "触覚フィードバック", description: "集中開始・終了などを触覚で知らせます。", status: "native", category: "native" },
  { id: "push", title: "プッシュ通知", description: "復習や目標の通知をネイティブ版で検討します。", status: "native", category: "native" },
  { id: "widgets", title: "ウィジェット", description: "今日の復習やタイマーをホーム画面に出す構想です。", status: "native", category: "native" },
];

export const notices: NoticeItem[] = [
  { category: "アップデート", date: "2026.07.16", title: "画面構成を5タブへ整理中", body: "ホーム・学習・教材・進捗・カフェを軸に、既存機能を壊さず導線を整理しています。" },
  { category: "お知らせ", date: "2026.07.16", title: "公開ライブラリではなく.recaloop配布を優先", body: "教材配布はまず.recaloopファイルで安定させ、公開機能は後から整理します。" },
  { category: "今後の展開", date: "2026.07.16", title: "カフェ機能はComing Soon", body: "現在は世界観とロードマップのみ表示し、操作できる偽データは出しません。" },
];

export const roadmapItems: RoadmapItem[] = [
  { phase: "早期導入", title: "勉強時間の手動記録", status: "開発中" },
  { phase: "早期導入", title: "タイマー", status: "デザイン中" },
  { phase: "早期導入", title: "ポモドーロ", status: "デザイン中" },
  { phase: "早期導入", title: "目標", status: "開発中" },
  { phase: "早期導入", title: "教材の教科設定", status: "開発中" },
  { phase: "早期導入", title: "教材作成の簡略化", status: "開発中" },
  { phase: "早期導入", title: "模試・テスト結果", status: "開発中" },
  { phase: "次の段階", title: "カフェ集中", status: "デザイン中" },
  { phase: "次の段階", title: "リスニングプレーヤー", status: "構想中" },
  { phase: "次の段階", title: "問題ごとのノート・画像", status: "構想中" },
  { phase: "次の段階", title: "学習共有画像", status: "構想中" },
  { phase: "次の段階", title: "カフェ基本機能", status: "デザイン中" },
  { phase: "ネイティブアプリ化後", title: "触覚フィードバック", status: "構想中" },
  { phase: "ネイティブアプリ化後", title: "プッシュ通知", status: "構想中" },
  { phase: "ネイティブアプリ化後", title: "イマジナリーフレンド", status: "構想中" },
  { phase: "ネイティブアプリ化後", title: "ウィジェット", status: "構想中" },
  { phase: "ネイティブアプリ化後", title: "ライブアクティビティ", status: "構想中" },
  { phase: "ネイティブアプリ化後", title: "アプリアイコン変更", status: "構想中" },
  { phase: "ネイティブアプリ化後", title: "スクリーンタイムによるアプリブロック", status: "構想中" },
];

export function statusClass(status: FeatureStatus) {
  return `feature-status ${status}`;
}

export type FeatureActionHandler = (action: NonNullable<FeatureDefinition["action"]>) => void;

export type FeatureIconMap = Record<string, ReactNode>;
