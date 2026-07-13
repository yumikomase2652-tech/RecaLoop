"use client";

import { useMemo,useState } from "react";
import { createStoredZip,downloadRecaloopPackage } from "@/lib/recaloop-package";

const encoder = new TextEncoder();
const sampleCsv = `数学,第1章,1,,,,[0001.png];
数学,第1章,2,,,,問題[0002.png];答えは4
英語,単語,1,,,,[front.png];[back.png]`;

export default function DeckBuilderPage(){
  const[title,setTitle]=useState("RecaLoopデッキ"),[description,setDescription]=useState(""),[csv,setCsv]=useState(sampleCsv),[files,setFiles]=useState<File[]>([]),[message,setMessage]=useState("");
  const mediaNames=useMemo(()=>files.map(file=>file.name),[files]);
  const addFiles=(next:FileList|null)=>{if(!next?.length)return;setFiles(current=>{const map=new Map(current.map(file=>[file.name,file]));Array.from(next).forEach(file=>map.set(file.name,file));return[...map.values()]})};
  const insertRef=(name:string)=>setCsv(value=>`${value}${value.endsWith("\n")||!value?"":"\n"},,,,,,[${name}];`);
  const exportDeck=async()=>{
    setMessage("");
    try{
      const deckId=`deck_${crypto.randomUUID()}`,now=new Date().toISOString();
      const deck={deckId,title:title.trim()||"RecaLoopデッキ",description:description.trim()||null,createdAt:now,updatedAt:now,appVersion:"recaloop-web",reviewMode:"default"};
      const media=await Promise.all(files.map(async file=>({path:`media/${file.name}`,data:new Uint8Array(await file.arrayBuffer())})));
      const blob=createStoredZip([{path:"deck.json",data:encoder.encode(JSON.stringify(deck,null,2))},{path:"cards.csv",data:encoder.encode(csv)},...media]);
      downloadRecaloopPackage(blob,deck.title);
      setMessage(".recaloopを書き出しました。");
    }catch(error){
      console.error("local deck export failed",error);
      setMessage(error instanceof Error?error.message:".recaloopの書き出しに失敗しました。");
    }
  };
  return <main className="min-h-screen bg-[#f4f7f8] p-4 md:p-8">
    <div className="mx-auto max-w-5xl">
      <header className="mb-6">
        <p className="text-xs font-bold text-[#607482]">ローカル専用・ログイン不要</p>
        <h1 className="text-3xl font-black text-[#172f42]">RecaLoop デッキ作成</h1>
        <p className="mt-2 text-sm text-[#607482]">CSVと画像・音声をまとめて、通常のZIP形式の .recaloop ファイルを書き出します。</p>
      </header>
      <section className="grid gap-4 md:grid-cols-[1fr_320px]">
        <div className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-[#dbe5ea]">
          <label className="block text-sm font-black text-[#172f42]">デッキ名<input className="mt-2 w-full rounded-2xl border border-[#d5dfe4] px-4 py-3 text-sm outline-none" value={title} onChange={e=>setTitle(e.target.value)}/></label>
          <label className="mt-4 block text-sm font-black text-[#172f42]">説明<textarea className="mt-2 min-h-20 w-full rounded-2xl border border-[#d5dfe4] px-4 py-3 text-sm outline-none" value={description} onChange={e=>setDescription(e.target.value)} placeholder="版、年度、注意点などもここに書けます。"/></label>
          <label className="mt-4 block text-sm font-black text-[#172f42]">cards.csv<textarea className="mt-2 min-h-[320px] w-full rounded-2xl border border-[#d5dfe4] px-4 py-3 font-mono text-sm outline-none" value={csv} onChange={e=>setCsv(e.target.value)} spellCheck={false}/></label>
          <div className="mt-4 rounded-2xl bg-[#f7fafb] p-4 text-xs text-[#607482]">
            <b className="text-[#172f42]">形式</b>
            <p className="mt-1">階層1,階層2,階層3,階層4,階層5,問題番号,表面;裏面</p>
            <p className="mt-1">メディアは本文中に <code>[ファイル名]</code> と書きます。裏面なしは <code>[画像.png];</code> のように空欄でOKです。</p>
          </div>
        </div>
        <aside className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-[#dbe5ea]">
          <h2 className="text-lg font-black text-[#172f42]">メディア</h2>
          <label onDragOver={e=>e.preventDefault()} onDrop={e=>{e.preventDefault();addFiles(e.dataTransfer.files)}} className="mt-3 flex min-h-36 cursor-pointer flex-col items-center justify-center rounded-3xl border border-dashed border-[#b9c7cf] bg-[#f8fafb] p-4 text-center text-sm font-bold text-[#607482]">
            ドラッグ&ドロップ<br/>またはファイル選択
            <input type="file" multiple accept="image/jpeg,image/png,image/webp,image/gif,audio/mpeg,audio/mp4,audio/wav,audio/ogg,.m4a" hidden onChange={e=>addFiles(e.target.files)}/>
          </label>
          <div className="mt-4 space-y-2">
            {mediaNames.map(name=><div key={name} className="flex items-center justify-between gap-2 rounded-2xl bg-[#f7fafb] px-3 py-2 text-xs"><span className="min-w-0 truncate font-bold text-[#172f42]">{name}</span><button className="shrink-0 rounded-full bg-[#17334a] px-3 py-1 font-bold text-white" onClick={()=>insertRef(name)}>[ ] 挿入</button></div>)}
            {!mediaNames.length&&<p className="text-sm text-[#718398]">まだメディアがありません。</p>}
          </div>
          <button onClick={exportDeck} className="mt-5 w-full rounded-2xl bg-[#17334a] px-4 py-3 text-sm font-black text-white">.recaloopを書き出す</button>
          {message&&<p className="mt-3 rounded-2xl bg-[#eef5f8] p-3 text-sm font-bold text-[#17334a]">{message}</p>}
        </aside>
      </section>
    </div>
  </main>
}
