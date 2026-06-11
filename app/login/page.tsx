"use client";
import { useState } from "react";
import Link from "next/link";
import { Sparkles } from "lucide-react";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/client";

export default function LoginPage(){
  const [email,setEmail]=useState("");const [password,setPassword]=useState("");const [signup,setSignup]=useState(false);const [message,setMessage]=useState("");
  async function submit(e:React.FormEvent){e.preventDefault();if(!hasSupabaseEnv){setMessage("デモモードです。ホームから機能を確認できます。");return}const supabase=createClient();const result=signup?await supabase.auth.signUp({email,password}):await supabase.auth.signInWithPassword({email,password});setMessage(result.error?.message|| (signup?"確認メールを送信しました":"ログインしました"))}
  return <main className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-[#e9f7ff] via-white to-[#ebfbf5]"><div className="card w-full max-w-md p-7 md:p-9"><div className="w-12 h-12 rounded-2xl bg-[#dff1ff] text-[#278dc5] flex items-center justify-center mb-5"><Sparkles/></div><h1 className="text-3xl font-black">RecaLoop</h1><p className="text-sm text-[#718398] mt-1">忘れる前に、もう一度。</p><form className="space-y-3 mt-8" onSubmit={submit}><input required type="email" className="field" placeholder="メールアドレス" value={email} onChange={e=>setEmail(e.target.value)}/><input required type="password" minLength={6} className="field" placeholder="パスワード" value={password} onChange={e=>setPassword(e.target.value)}/><button className="btn bg-[#278dc5] text-white w-full">{signup?"アカウントを作成":"ログイン"}</button></form>{message&&<p className="text-xs mt-4 rounded-xl bg-[#fff2b8] p-3">{message}</p>}<button onClick={()=>setSignup(!signup)} className="text-sm font-bold text-[#278dc5] w-full mt-5">{signup?"ログインに戻る":"はじめての方はこちら"}</button><Link href="/" className="block text-center text-xs text-[#718398] mt-5">デモ画面を見る</Link></div></main>
}
