import type { Rating, ReviewRuleFields, ReviewState } from "./types";

const defaultIntervals = [1, 3, 7, 14, 30, 60];

export function calculateNextReview(rating:Rating,current?:Partial<ReviewState>,reviewedAt=new Date(),rule?:ReviewRuleFields):ReviewState{
 const maxReviews=rule?.max_reviews===undefined?null:rule.max_reviews,intervals=rule?.review_intervals?.length?rule.review_intervals:defaultIntervals,priorStep=current?.review_step||0,nextCount=(current?.review_count||0)+1;
 let nextStep=priorStep,days=0;
 if(rating==="again"){nextStep=rule?.reset_again_to_first?0:Math.max(0,priorStep-1);days=0}
 else if(rating==="hard"){nextStep=priorStep;days=1}
 else{nextStep=priorStep+(rating==="easy"?2:1);days=intervals[Math.min(Math.max(nextStep,1),intervals.length)-1]||intervals.at(-1)||1}
 const completed=maxReviews===0||typeof maxReviews==="number"&&nextCount>=maxReviews,due=new Date(reviewedAt);
 if(completed)return{last_rating:rating,unknown_flag:Boolean(current?.unknown_flag),review_count:nextCount,review_step:nextStep,is_completed:true,due_at:null,next_review_date:null};
 due.setDate(due.getDate()+days);
 return{last_rating:rating,unknown_flag:Boolean(current?.unknown_flag),review_count:nextCount,review_step:nextStep,is_completed:false,due_at:due.toISOString(),next_review_date:due.toISOString().slice(0,10)}
}
