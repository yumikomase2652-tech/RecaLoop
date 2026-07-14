import type { CsvPreview, MaterialNode, WordCard } from "./types";
const parse=(text:string)=>{const rows:string[][]=[],current:string[]=[],input=text.replace(/^\uFEFF/,"");let cell="",quoted=false;for(let i=0;i<input.length;i++){const ch=input[i],next=input[i+1];if(quoted&&ch==='"'&&next==='"'){cell+='"';i++}else if(ch==='"')quoted=!quoted;else if(!quoted&&ch===","){current.push(cell.trim());cell=""}else if(!quoted&&(ch==="\n"||ch==="\r")){if(ch==="\r"&&next==="\n")i++;current.push(cell.trim());if(current.some(Boolean))rows.push([...current]);current.length=0;cell=""}else cell+=ch}current.push(cell.trim());if(current.some(Boolean))rows.push(current);return rows};
function splitFrontBack(value:string){const [front,...rest]=value.split(";");return{front:(front||"").trim(),back:rest.join(";").trim()}}
function splitProblemAndContent(cells:string[]){const last=cells.at(-1)||"",hasContent=last.includes(";");return hasContent?{problemNumber:cells.at(-2)||"",content:last,hierarchy:cells.slice(0,-2)}:{problemNumber:last,content:"",hierarchy:cells.slice(0,-1)}}
export function previewMaterialCsv(text:string,deckId:string):CsvPreview<MaterialNode>{
 const input=parse(text);if(!input.length)return{rows:[],itemCount:0,duplicateKeys:[],skippedHeader:false};
 const header=input[0].filter(Boolean).every(cell=>/^(chapter|section|folder|item|level\s*\d*|階層\s*\d*|章|節|問題|問題番号|表面|裏面|front|back)$/i.test(cell));const rows=header?input.slice(1):input;
 const nodes:MaterialNode[]=[],folders=new Map<string,string>(),seen=new Set<string>(),duplicates=new Set<string>();
 rows.forEach((raw,rowIndex)=>{const cells=raw.map(v=>v.trim()),{problemNumber:itemTitle,content,hierarchy}=splitProblemAndContent(cells),folderCells=hierarchy.filter(Boolean);if(!itemTitle&&!content)return;const full=[...folderCells,itemTitle,content].join(" / ");if(seen.has(full))duplicates.add(full);seen.add(full);let parent:string|null=null,path="";
  folderCells.slice(0,6).forEach((title,index)=>{path=path?`${path} / ${title}`:title;if(!folders.has(path)){const id=`csv-f-${folders.size}`;folders.set(path,id);nodes.push({id,deck_id:deckId,parent_id:parent,node_type:"folder",title,memo:null,order_index:index,created_at:new Date().toISOString()})}parent=folders.get(path)!});
  nodes.push({id:`csv-i-${rowIndex}`,deck_id:deckId,parent_id:parent,node_type:"item",title:itemTitle,memo:content||null,order_index:rowIndex,created_at:new Date().toISOString()});
 });return{rows:nodes,itemCount:nodes.filter(n=>n.node_type==="item").length,duplicateKeys:[...duplicates],skippedHeader:header};
}
export function previewWordCsv(text:string,listId:string):CsvPreview<WordCard>{
 const input=parse(text);if(!input.length)return{rows:[],itemCount:0,duplicateKeys:[],skippedHeader:false,columns:{}};
 const first=input[0].map(v=>v.toLowerCase()),hasHeader=first.includes("front")&&first.includes("back"),header=hasHeader?first:[],rows=hasHeader?input.slice(1):input;
 const idx=(name:string)=>header.indexOf(name),idIndex=hasHeader?Math.max(idx("card_id"),idx("id")):-1,frontIndex=hasHeader?idx("front"):-1,backIndex=hasHeader?idx("back"):-1,memoIndex=hasHeader?idx("memo"):-1;
 const seen=new Set<string>(),duplicates=new Set<string>(),cards:WordCard[]=[];
 rows.forEach((r,i)=>{let cardId:string|null=null,front="",back="",memo:string|null=null;
  if(hasHeader){cardId=idIndex>=0?r[idIndex]||null:null;front=r[frontIndex]||"";back=r[backIndex]||"";memo=memoIndex>=0?r[memoIndex]||null:null}
  else{const cells=r.map(v=>v.trim()),{problemNumber,content,hierarchy}=splitProblemAndContent(cells),pair=splitFrontBack(content);cardId=problemNumber||null;front=pair.front;back=pair.back;memo=hierarchy.filter(Boolean).join(" / ")||null}
  if(front&&!back)back="";
  if(!cardId&&!front&&!back)return;const key=cardId||`${front}\u0000${back}`;if(seen.has(key))duplicates.add(cardId||`${front} / ${back}`);seen.add(key);cards.push({id:`csv-w-${i}`,list_id:listId,card_id:cardId,front,back,memo,order_index:i,created_at:new Date().toISOString()})
 });
 const columns=hasHeader?{card_id:idIndex>=0?String(idIndex+1):"なし",front:String(frontIndex+1),back:String(backIndex+1),memo:memoIndex>=0?String(memoIndex+1):"なし"}:{card_id:"最後の列、または表面;裏面の1つ前",front:";ありの最後の列",back:";ありの最後の列",memo:"先頭〜問題番号前"};
 return{rows:cards,itemCount:cards.length,duplicateKeys:[...duplicates],skippedHeader:hasHeader,columns}
}
