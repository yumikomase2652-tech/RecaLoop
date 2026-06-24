"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { BookCopy, BookOpen, Layers3, Search, Trophy } from "lucide-react";
import { AppRouteNav } from "@/components/app-route-nav";
import { copySharedCards, copySharedMaterial, loadLibrary } from "@/lib/recaloop-data";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/client";
import type { LibraryItem } from "@/lib/types";

export function LibraryApp() {
  const [items, setItems] = useState<LibraryItem[]>([]);
  const [query, setQuery] = useState("");
  const [type, setType] = useState("all");
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");

  const search = async (q = query, selectedType = type) => {
    setLoading(true);
    setMessage("");
    try {
      setItems(await loadLibrary(q, selectedType));
    } catch (error) {
      setMessage((error as Error).message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLibrary("", "all")
      .then(setItems)
      .catch((error) => setMessage((error as Error).message))
      .finally(() => setLoading(false));
  }, []);

  const changeType = (nextType: string) => {
    setType(nextType);
    search(query, nextType);
  };

  const copy = async (item: LibraryItem) => {
    if (hasSupabaseEnv) {
      const { data: { user } } = await createClient().auth.getUser();
      if (!user) {
        location.href = "/login";
        return;
      }
    }
    if (item.content_type === "material") await copySharedMaterial(item.share_token);
    else await copySharedCards(item.share_token);
    location.href = "/dashboard";
  };

  return <><AppRouteNav active="library" /><main className="app-page min-h-screen p-4 pb-28 md:p-10">
    <div className="max-w-6xl mx-auto">
      <div className="flex flex-wrap justify-between gap-3 items-end mt-3">
       <div>
        <h1 className="text-2xl font-black">公開ライブラリ</h1>
        <p className="text-xs text-[#718398] mt-1">運営が確認・承認した問題集と暗記カードだけを掲載しています。</p>
       </div>
       <Link href="/rankings" className="secondary-button"><Trophy size={16} />ランキング</Link>
      </div>
      <div className="deck-toolbar">
        <div className="deck-search">
          <Search size={16} />
          <input value={query} onChange={(event) => setQuery(event.target.value)} onKeyDown={(event) => event.key === "Enter" && search()} placeholder="タイトルで検索" />
        </div>
        <div className="deck-filters">
          {[["all", "すべて"], ["material", "問題集"], ["cards", "暗記カード"]].map(([id, label]) =>
            <button key={id} onClick={() => changeType(id)} className={`filter-chip ${type === id ? "active" : ""}`}>{label}</button>)}
          <button onClick={() => search()} className="primary-button">検索</button>
        </div>
      </div>
      {message && <p className="notice mt-4">{message}</p>}
      <div className="grid md:grid-cols-2 gap-4 mt-7">
        {items.map((item) => <article className="surface p-5" key={`${item.content_type}-${item.id}`}>
          <div className="flex justify-between">
            <span className="tag neutral">{item.content_type === "material" ? "問題集" : "暗記カード"}</span>
            {item.content_type === "material" ? <BookOpen size={18} /> : <Layers3 size={18} />}
          </div>
          <h2 className="font-black text-lg mt-4">{item.title}</h2>
          <div className="flex gap-4 text-xs text-[#71818d] mt-4">
            <span>{item.item_count}{item.content_type === "material" ? "問" : "枚"}</span>
            <span>{item.copy_count}コピー</span>
            <span>{new Date(item.updated_at).toLocaleDateString("ja-JP")}</span>
          </div>
          {(item.clear_titles?.length || 0) > 0 && <div className="clear-title-panel">{item.clear_titles?.map((title) => <div key={title.name}><b><Trophy size={14} />デッキ完走称号</b><span>{title.name}</span><strong>{title.count}人</strong></div>)}</div>}
          <div className="flex gap-2 mt-5">
            <Link href={`/share/${item.content_type}/${item.share_token}`} className="secondary-button flex-1">内容を見る</Link>
            <button onClick={() => copy(item)} className="primary-button flex-1"><BookCopy size={15} />コピーして使う</button>
          </div>
        </article>)}
      </div>
      {!loading && !items.length && <div className="surface p-10 text-center mt-7"><b>該当する公開コンテンツはありません。</b></div>}
      {loading && <p className="text-sm text-[#71818d] mt-8">読み込み中...</p>}
    </div>
  </main></>;
}
