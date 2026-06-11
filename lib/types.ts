export type Role = "student" | "teacher";
export type UnitType = "page" | "problem" | "lesson" | "word";
export type Understanding = "good" | "normal" | "bad";
export type ReviewStatus = "pending" | "done";

export interface Material {
  id: string; title: string; subject: string; unit_type: UnitType;
  total_units: number; current_unit: number; created_at: string;
}
export interface Review {
  id: string; material_id: string; material_title: string; subject: string;
  start_unit: number; end_unit: number; review_date: string; review_count: number; status: ReviewStatus;
}
export interface Flashcard {
  id: string; deck_name: string; subject: string; front: string; back: string;
  memo: string; difficulty: "easy" | "normal" | "hard"; next_review_date: string; review_count: number;
}
export interface Assignment {
  id: string; title: string; description: string; due_date: string; status: "assigned" | "done"; teacher_name: string;
}
