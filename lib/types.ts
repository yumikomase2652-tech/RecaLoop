export type Rating = "again" | "hard" | "good" | "easy";
export type TargetType = "material" | "word";

export type Visibility="private"|"unlisted"|"submitted"|"approved"|"rejected";
export interface Profile { id:string; display_name:string; coin_balance:number; is_admin?:boolean; total_exp?:number; level?:number; equipped_title_id?:string|null; target_school?:string|null; exam_year?:number|null; study_goal?:string|null; created_at:string }
export interface TitleDefinition { id:string; title_key:string; display_name:string; title_type:"level"|"deck_completion"; condition_json:Record<string,unknown>; created_at:string }
export interface UserTitle { id:string; user_id:string; title_id:string; source_type:string|null; source_id:string|null; earned_at:string; title:TitleDefinition }
export interface ReviewState { last_rating:Rating|null; unknown_flag:boolean; review_count:number; due_at:string|null; next_review_date:string|null }
export interface MaterialDeck { id:string; user_id:string; title:string; subject:string|null; description:string|null; is_public?:boolean; share_token?:string; visibility?:Visibility; submitted_at?:string|null; approved_at?:string|null; rejected_reason?:string|null; submission_kind?:"initial"|"update"|null; pending_snapshot?:unknown; published_snapshot?:unknown; created_by_user_id?:string|null; source_content_id?:string|null; copy_count?:number; updated_at?:string; created_at:string }
export interface MaterialNode { id:string; deck_id:string; parent_id:string|null; node_type:"folder"|"item"; title:string; memo:string|null; order_index:number; created_at:string; state?:ReviewState }
export interface MaterialAttempt { id:string; user_id:string; material_node_id:string; rating:Rating|null; unknown_flag:boolean; action?:"review"|"check"; reviewed_at:string; created_at:string }
export interface WordList { id:string; user_id:string; title:string; subject:string|null; description:string|null; is_public?:boolean; share_token?:string; visibility?:Visibility; submitted_at?:string|null; approved_at?:string|null; rejected_reason?:string|null; submission_kind?:"initial"|"update"|null; pending_snapshot?:unknown; published_snapshot?:unknown; created_by_user_id?:string|null; source_content_id?:string|null; copy_count?:number; updated_at?:string; created_at:string }
export interface WordCard { id:string; list_id:string; card_id:string|null; front:string; back:string; memo:string|null; order_index:number; created_at:string; state?:ReviewState }
export interface WordAttempt { id:string; user_id:string; word_card_id:string; rating:Rating|null; unknown_flag:boolean; action?:"review"|"check"; reviewed_at:string; created_at:string }
export interface ReviewTarget { id:string; target_type:TargetType; group_id:string; group_title:string; context?:string; title:string; card_id?:string|null; front?:string; back?:string; memo?:string|null; state:ReviewState }
export interface AppData { profile:Profile|null; titles:TitleDefinition[]; userTitles:UserTitle[]; materialDecks:MaterialDeck[]; materialNodes:MaterialNode[]; materialAttempts:MaterialAttempt[]; wordLists:WordList[]; wordCards:WordCard[]; wordAttempts:WordAttempt[] }
export interface CsvPreview<T> { rows:T[]; itemCount:number; duplicateKeys:string[]; skippedHeader:boolean }
export interface SharedMaterial { deck:MaterialDeck; nodes:MaterialNode[] }
export interface SharedCards { list:WordList; cards:WordCard[] }
export interface ClearTitle { name:string; count:number }
export interface LibraryItem { content_type:"material"|"cards"; id:string; title:string; creator_name:string; item_count:number; copy_count:number; updated_at:string; share_token:string; clear_titles?:ClearTitle[] }
export interface Submission extends LibraryItem { description:string|null; submitted_at:string; rejected_reason:string|null; submission_kind?:"initial"|"update" }
export interface RankingItem { content_type:"material"|"cards"; id:string; title:string; creator_name:string; copy_count:number; sample_count:number; average_progress:number|null; completion_rate:number|null; continuation_rate:number|null; approved_at:string; last_copied_at?:string|null }
export interface ReviewResult { exp_gained:number; new_titles:string[]; deck_completed:boolean }
