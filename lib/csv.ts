import type { CsvPreview, MaterialNode, WordCard } from "./types";
const parse=(text:string)=>text.replace(/^\uFEFF/,"").split(/\r?\n/).map(line=>line.split(",").map(v=>v.trim().replace(/^"|"$/g,""))).filter(row=>row.some(Boolean));
export function previewMaterialCsv(text:string,deckId:string):CsvPreview<MaterialNode>{
 const input=parse(text);if(!input.length)return{rows:[],itemCount:0,duplicateKeys:[],skippedHeader:false};
 const header=input[0].filter(Boolean).every(cell=>/^(chapter|section|folder|item|level\s*\d*|階層\s*\d*|章|節|問題|問題番号)$/i.test(cell));const rows=header?input.slice(1):input;
 const nodes:MaterialNode[]=[],folders=new Map<string,string>(),seen=new Set<string>(),duplicates=new Set<string>();
 rows.forEach((raw,rowIndex)=>{const cells=raw.filter(Boolean);if(!cells.length)return;const full=cells.join(" / ");if(seen.has(full))duplicates.add(full);seen.add(full);let parent:string|null=null,path="";
  cells.slice(0,-1).forEach((title,index)=>{path=path?`${path} / ${title}`:title;if(!folders.has(path)){const id=`csv-f-${folders.size}`;folders.set(path,id);nodes.push({id,deck_id:deckId,parent_id:parent,node_type:"folder",title,memo:null,order_index:index,created_at:new Date().toISOString()})}parent=folders.get(path)!});
  nodes.push({id:`csv-i-${rowIndex}`,deck_id:deckId,parent_id:parent,node_type:"item",title:cells.at(-1)!,memo:null,order_index:rowIndex,created_at:new Date().toISOString()});
 });return{rows:nodes,itemCount:nodes.filter(n=>n.node_type==="item").length,duplicateKeys:[...duplicates],skippedHeader:header};
}
export function previewWordCsv(text:string,listId:string):CsvPreview<WordCard>{
 const input=parse(text);if(!input.length)return{rows:[],itemCount:0,duplicateKeys:[],skippedHeader:false,columns:{}};
 const first=input[0].map(v=>v.toLowerCase()),hasHeader=first.includes("front")&&first.includes("back"),header=hasHeader?first:[],rows=hasHeader?input.slice(1):input;
 const idx=(name:string)=>header.indexOf(name),idIndex=hasHeader?Math.max(idx("card_id"),idx("id")):-1,frontIndex=hasHeader?idx("front"):-1,backIndex=hasHeader?idx("back"):-1,memoIndex=hasHeader?idx("memo"):-1;
 const seen=new Set<string>(),duplicates=new Set<string>(),cards:WordCard[]=[];
 rows.forEach((r,i)=>{let cardId:string|null=null,front="",back="",memo:string|null=null;
  if(hasHeader){cardId=idIndex>=0?r[idIndex]||null:null;front=r[frontIndex]||"";back=r[backIndex]||"";memo=memoIndex>=0?r[memoIndex]||null:null}
  else if(r.length>=3){cardId=r[0]||null;front=r[1]||"";back=r[2]||"";memo=r[3]||null}
  else{front=r[0]||"";back=r[1]||"";memo=r[2]||null}
  if(!front||!back)return;const key=cardId||`${front}\u0000${back}`;if(seen.has(key))duplicates.add(cardId||`${front} / ${back}`);seen.add(key);cards.push({id:`csv-w-${i}`,list_id:listId,card_id:cardId,front,back,memo,order_index:i,created_at:new Date().toISOString()})
 });
 const columns=hasHeader?{card_id:idIndex>=0?String(idIndex+1):"なし",front:String(frontIndex+1),back:String(backIndex+1),memo:memoIndex>=0?String(memoIndex+1):"なし"}:rows[0]?.length>=3?{card_id:"1",front:"2",back:"3",memo:rows[0]?.length>=4?"4":"なし"}:{card_id:"なし",front:"1",back:"2",memo:rows[0]?.length>=3?"3":"なし"};
 return{rows:cards,itemCount:cards.length,duplicateKeys:[...duplicates],skippedHeader:hasHeader,columns}
}
