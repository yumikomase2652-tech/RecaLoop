import type { Assignment, Flashcard, Material, Review } from "./types";

const iso = (offset = 0) => {
  const d = new Date(); d.setDate(d.getDate() + offset); return d.toISOString().slice(0, 10);
};

export const demoMaterials: Material[] = [
  { id: "m1", title: "ターゲット1900", subject: "英語", unit_type: "word", total_units: 1900, current_unit: 680, created_at: iso(-30) },
  { id: "m2", title: "青チャート 数学IA", subject: "数学", unit_type: "problem", total_units: 500, current_unit: 215, created_at: iso(-24) },
  { id: "m3", title: "物理重要問題集", subject: "物理", unit_type: "problem", total_units: 150, current_unit: 42, created_at: iso(-15) },
];
export const demoReviews: Review[] = [
  { id: "r1", material_id: "m1", material_title: "ターゲット1900", subject: "英語", start_unit: 621, end_unit: 650, review_date: iso(), review_count: 1, status: "pending" },
  { id: "r2", material_id: "m2", material_title: "青チャート 数学IA", subject: "数学", start_unit: 201, end_unit: 210, review_date: iso(), review_count: 0, status: "pending" },
  { id: "r3", material_id: "m3", material_title: "物理重要問題集", subject: "物理", start_unit: 31, end_unit: 38, review_date: iso(-1), review_count: 2, status: "pending" },
];
export const demoCards: Flashcard[] = [
  { id: "c1", deck_name: "英単語 基礎", subject: "英語", front: "acquire", back: "獲得する、身につける", memo: "知識や技能を得る時によく使う", difficulty: "normal", next_review_date: iso(), review_count: 2 },
  { id: "c2", deck_name: "英単語 基礎", subject: "英語", front: "inevitable", back: "避けられない、必然的な", memo: "", difficulty: "hard", next_review_date: iso(), review_count: 1 },
  { id: "c3", deck_name: "古文単語", subject: "国語", front: "をかし", back: "趣がある、面白い", memo: "", difficulty: "easy", next_review_date: iso(2), review_count: 4 },
];
export const demoAssignments: Assignment[] = [
  { id: "a1", title: "青チャート例題 211〜225", description: "解けなかった問題には印をつけよう", due_date: iso(2), status: "assigned", teacher_name: "佐藤先生" },
  { id: "a2", title: "英単語 651〜700 復習", description: "3周して定着度を確認", due_date: iso(4), status: "assigned", teacher_name: "佐藤先生" },
];
