"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { GraduationCap, UserRound } from "lucide-react";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/client";

export default function SetupPage(){const router=useRouter();const [name,setName]=useState("");const [roles,setRoles]=useState<string[]>(["student"]);
const toggle=(r:string)=>setRoles(x=>x.includes(r)?x.filter(v=>v!==r):[...x,r]);
async function save(e:React.FormEvent){e.preventDefault();if(hasSupabaseEnv){const s=createClient();const {data}=await s.auth.getUser();if(data.user)await s.from("profiles").update({display_name:name,roles}).eq("id",data.user.id)}router.push("/")}
return <main className="min-h-screen flex items-center justify-center p-4"><form onSubmit={save} className="card p-7 w-full max-w-lg"><p className="text-xs font-bold text-[#278dc5]">初期設定</p><h1 className="text-2xl font-black mt-2">RecaLoopをはじめよう</h1><p className="text-sm text-[#718398] mt-2">役割はあとから追加・変更できます。</p><input required className="field mt-7" placeholder="表示名" value={name} onChange={e=>setName(e.target.value)}/><div className="grid grid-cols-2 gap-3 mt-4"><Role active={roles.includes("student")} click={()=>toggle("student")} icon={<UserRound/>} title="生徒" sub="自分の学習を管理"/><Role active={roles.includes("teacher")} click={()=>toggle("teacher")} icon={<GraduationCap/>} title="先生" sub="生徒の学習を支援"/></div><button disabled={!roles.length} className="btn bg-[#278dc5] text-white w-full mt-6">設定を保存</button></form></main>}
function Role({active,click,icon,title,sub}:{active:boolean;click:()=>void;icon:React.ReactNode;title:string;sub:string}){return <button type="button" onClick={click} className={"text-left rounded-2xl border-2 p-4 "+(active?"border-[#65b8e7] bg-[#e9f7ff]":"border-[#e8eef2] bg-white")}><span className="text-[#278dc5]">{icon}</span><b className="block mt-3">{title}</b><span className="text-xs text-[#718398]">{sub}</span></button>}
