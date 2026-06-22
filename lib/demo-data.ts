import type { AppData, MaterialNode, ReviewState, WordCard } from "./types";
const now=new Date(),date=(days:number)=>{const d=new Date(now);d.setDate(d.getDate()+days);return d.toISOString().slice(0,10)},iso=now.toISOString();
const state=(rating:"again"|"hard"|"good"|"easy"|null,days:number):ReviewState=>({last_rating:rating,unknown_flag:rating==="hard",review_count:rating?2:0,due_at:rating?new Date(now.getTime()+days*86400000).toISOString():null,next_review_date:rating?date(days):null});
export const demoMaterialNodes:MaterialNode[]=[
 {id:"m-folder-1",deck_id:"deck-1",parent_id:null,node_type:"folder",title:"第1章 物質の構成",memo:null,order_index:0,created_at:iso},
 {id:"m-folder-2",deck_id:"deck-1",parent_id:"m-folder-1",node_type:"folder",title:"第1回 原子",memo:null,order_index:0,created_at:iso},
 {id:"m-item-1",deck_id:"deck-1",parent_id:"m-folder-2",node_type:"item",title:"問1",memo:"周期表を確認",order_index:0,created_at:iso,state:state("hard",0)},
 {id:"m-item-2",deck_id:"deck-1",parent_id:"m-folder-2",node_type:"item",title:"問2",memo:null,order_index:1,created_at:iso,state:state("good",3)},
];
export const demoWordCards:WordCard[]=[
 {id:"w-1",list_id:"list-1",card_id:"001",front:"apple",back:"りんご",memo:"名詞",order_index:0,created_at:iso,state:state("again",0)},
 {id:"w-2",list_id:"list-1",card_id:"A-12",front:"review",back:"復習する",memo:"動詞",order_index:1,created_at:iso,state:state("easy",7)},
];
export const demoData:AppData={profile:{id:"demo-user",display_name:"デモユーザー",coin_balance:0,created_at:iso},materialDecks:[{id:"deck-1",user_id:"demo-user",title:"エクセル化学",subject:null,description:"問題番号だけを管理",is_public:false,share_token:"demo-material",created_at:iso}],materialNodes:demoMaterialNodes,materialAttempts:[{id:"ma-1",user_id:"demo-user",material_node_id:"m-item-1",rating:"hard",unknown_flag:true,reviewed_at:iso,created_at:iso}],wordLists:[{id:"list-1",user_id:"demo-user",title:"英単語100",subject:null,description:"自作暗記カード",is_public:false,share_token:"demo-cards",created_at:iso}],wordCards:demoWordCards,wordAttempts:[{id:"wa-1",user_id:"demo-user",word_card_id:"w-1",rating:"again",unknown_flag:false,reviewed_at:iso,created_at:iso}]};
