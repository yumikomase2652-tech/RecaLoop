import type { AppData, MaterialNode, ReviewState, TitleDefinition, WordCard } from "./types";

const now = new Date();
const iso = now.toISOString();
const date = (days: number) => { const value = new Date(now); value.setDate(value.getDate() + days); return value.toISOString().slice(0, 10); };
const state = (rating: "again" | "hard" | "good" | "easy" | null, days: number): ReviewState => ({ last_rating: rating, unknown_flag: rating === "hard", review_count: rating ? 2 : 0, due_at: rating ? new Date(now.getTime() + days * 86400000).toISOString() : null, next_review_date: rating ? date(days) : null });

export const demoMaterialNodes: MaterialNode[] = [
  { id: "m-folder-1", deck_id: "deck-1", parent_id: null, node_type: "folder", title: "第1章 物質の構成", memo: null, order_index: 0, created_at: iso },
  { id: "m-folder-2", deck_id: "deck-1", parent_id: "m-folder-1", node_type: "folder", title: "第1回 原子", memo: null, order_index: 0, created_at: iso },
  { id: "m-item-1", deck_id: "deck-1", parent_id: "m-folder-2", node_type: "item", title: "問1", memo: "周期表を確認", order_index: 0, created_at: iso, state: state("hard", 0) },
  { id: "m-item-2", deck_id: "deck-1", parent_id: "m-folder-2", node_type: "item", title: "問2", memo: null, order_index: 1, created_at: iso, state: state("good", 3) },
];
export const demoWordCards: WordCard[] = [
  { id: "w-1", list_id: "list-1", card_id: "001", front: "apple", back: "りんご", memo: "名詞", order_index: 0, created_at: iso, state: state("again", 0) },
  { id: "w-2", list_id: "list-1", card_id: "A-12", front: "review", back: "復習する", memo: "動詞", order_index: 1, created_at: iso, state: state("easy", 7) },
];

const demoTitles: TitleDefinition[] = [
  { id: "title-apprentice", title_key: "exp:100", display_name: "見習い学習者", title_type: "level", condition_json: { required_exp: 100 }, created_at: iso },
  { id: "title-starter", title_key: "exp:1000", display_name: "学びの軌道", title_type: "level", condition_json: { required_exp: 1000 }, created_at: iso },
  { id: "title-streak-7", title_key: "streak:7", display_name: "継続の芽", title_type: "streak", condition_json: { required_days: 7 }, created_at: iso },
  { id: "title-streak-30", title_key: "streak:30", display_name: "習慣化ビギナー", title_type: "streak", condition_json: { required_days: 30 }, created_at: iso },
  { id: "title-streak-100", title_key: "streak:100", display_name: "継続の達人", title_type: "streak", condition_json: { required_days: 100 }, created_at: iso },
  { id: "title-deck-1", title_key: "deck_completion:material:deck-1", display_name: "エクセル化学", title_type: "deck_completion", condition_json: { source_type: "material", source_id: "deck-1" }, created_at: iso },
];

export const demoData: AppData = {
  profile: { id: "demo-user", display_name: "デモユーザー", coin_balance: 0, is_admin: true, total_exp: 1995, level: 20, equipped_title_id: "title-continuity", target_school: "東京大学", grade_level: "高校3年生", grade_updated_year: now.getMonth() >= 3 ? now.getFullYear() : now.getFullYear() - 1, onboarding_completed: true, created_at: iso },
  titles: demoTitles,
  userTitles: demoTitles.slice(0, 4).map((title, index) => ({ id: `user-title-${index}`, user_id: "demo-user", title_id: title.id, source_type: title.title_type === "deck_completion" ? "material" : title.title_type, source_id: null, earned_at: new Date(now.getTime() - index * 86400000).toISOString(), title })),
  materialDecks: [{ id: "deck-1", user_id: "demo-user", title: "エクセル化学", subject: null, description: "問題番号だけを管理", is_public: true, share_token: "demo-material", visibility: "approved", approved_at: iso, created_by_user_id: "demo-user", copy_count: 1256, updated_at: iso, created_at: iso }],
  materialNodes: demoMaterialNodes,
  materialAttempts: [{ id: "ma-1", user_id: "demo-user", material_node_id: "m-item-1", rating: "hard", unknown_flag: true, action: "review", reviewed_at: iso, created_at: iso }],
  wordLists: [{ id: "list-1", user_id: "demo-user", title: "英単語100", subject: null, description: "自作暗記カード", is_public: false, share_token: "demo-cards", visibility: "submitted", submitted_at: iso, submission_kind: "initial", created_by_user_id: "demo-user", copy_count: 3, updated_at: iso, created_at: iso }],
  wordCards: demoWordCards,
  wordAttempts: [{ id: "wa-1", user_id: "demo-user", word_card_id: "w-1", rating: "again", unknown_flag: false, action: "review", reviewed_at: iso, created_at: iso }],
  studySessions: [{ id: "session-1", user_id: "demo-user", started_at: iso, ended_at: iso, duration_minutes: 18, related_type: "material_deck", related_id: "deck-1", created_at: iso }],
  expTransactions: [{ id: "exp-1", user_id: "demo-user", amount: 5, reason: "review_complete", reference_key: "demo-review", created_at: iso }],
};
