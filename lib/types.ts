export type Rating = "again" | "hard" | "good" | "easy";
export type TargetType = "material" | "word";

export interface Profile { id:string; display_name:string; coin_balance:number; created_at:string }
export interface ReviewState { last_rating:Rating|null; unknown_flag:boolean; review_count:number; due_at:string|null; next_review_date:string|null }
export interface MaterialDeck { id:string; user_id:string; title:string; subject:string|null; description:string|null; is_public?:boolean; share_token?:string; created_at:string }
export interface MaterialNode { id:string; deck_id:string; parent_id:string|null; node_type:"folder"|"item"; title:string; memo:string|null; order_index:number; created_at:string; state?:ReviewState }
export interface MaterialAttempt { id:string; user_id:string; material_node_id:string; rating:Rating; unknown_flag:boolean; reviewed_at:string; created_at:string }
export interface WordList { id:string; user_id:string; title:string; subject:string|null; description:string|null; is_public?:boolean; share_token?:string; created_at:string }
export interface WordCard { id:string; list_id:string; card_id:string|null; front:string; back:string; memo:string|null; order_index:number; created_at:string; state?:ReviewState }
export interface WordAttempt { id:string; user_id:string; word_card_id:string; rating:Rating; unknown_flag:boolean; reviewed_at:string; created_at:string }
export interface ReviewTarget { id:string; target_type:TargetType; group_id:string; group_title:string; title:string; card_id?:string|null; front?:string; back?:string; memo?:string|null; state:ReviewState }
export interface AppData { profile:Profile|null; materialDecks:MaterialDeck[]; materialNodes:MaterialNode[]; materialAttempts:MaterialAttempt[]; wordLists:WordList[]; wordCards:WordCard[]; wordAttempts:WordAttempt[] }
export interface CsvPreview<T> { rows:T[]; itemCount:number; duplicateKeys:string[]; skippedHeader:boolean }
export interface SharedMaterial { deck:MaterialDeck; nodes:MaterialNode[] }
export interface SharedCards { list:WordList; cards:WordCard[] }
