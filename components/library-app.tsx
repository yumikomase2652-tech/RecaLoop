"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { BookCopy, BookOpen, Layers3, Search, Trophy } from "lucide-react";
import { AppRouteNav } from "@/components/app-route-nav";
import { copySharedCards, copySharedCardsForStudent, copySharedMaterial, copySharedMaterialForStudent, loadLibrary } from "@/lib/recaloop-data";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/client";
import type { LibraryItem } from "@/lib/types";

export function LibraryApp() {
  const [items, setItems] = useState<LibraryItem[]>([]);
  const [query, setQuery] = useState("");
  const [type, setType] = useState("all");
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");
  const [viewer, setViewer] = useState<{ studentId: string; name: string } | null>(null);

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
    try {
      const raw = localStorage.getItem("recaloop-viewer");
      if (raw) setViewer(JSON.parse(raw));
    } catch {}
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
    const message = viewer ? `このデッキを ${viewer.name} さんの学習デッキにコピーしますか？` : "このデッキを自分の学習デッキにコピーしますか？";
    if (!confirm(message)) return;
    if (hasSupabaseEnv) {
      const { data: { user } } = await createClient().auth.getUser();
      if (!user) {
        location.href = "/login";
        return;
      }
    }
    if (item.content_type === "material") {
      if (viewer) await copySharedMaterialForStudent(item.share_token, viewer.studentId);
      else await copySharedMaterial(item.share_token);
    } else if (viewer) await copySharedCardsForStudent(item.share_token, viewer.studentId);
    else await copySharedCards(item.share_token);
    setMessage(viewer ? `${viewer.name}さんの学習デッキにコピーしました。` : "自分の学習デッキにコピーしました。");
    setTimeout(() => { location.href = "/dashboard"; }, 600);
  };

  return <><AppRouteNav active="library" /><main className="app-page min-h-screen p-4 pb-28 md:p-10">
    <div className="max-w-6xl mx-auto">
      {viewer && <button className="viewer-banner" onClick={() => { localStorage.removeItem("recaloop-viewer"); location.href = "/dashboard"; }}><b>{viewer.name}さんの画面を表示中</b><span>戻る</span></button>}
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
      <div className="grid md:grid-cols-2 gap-3 mt-5">
        {items.map((item) => <article className="surface library-compact-card" key={`${item.content_type}-${item.id}`}>
          <Link href={`/share/${item.content_type}/${item.share_token}`} className="library-card-main">
            <span className="tag neutral">{item.content_type === "material" ? "問題集" : "暗記カード"}</span>
            <div className="min-w-0">
              <h2>{item.title}</h2>
              <p>{item.item_count}{item.content_type === "material" ? "問" : "枚"} ・ {item.copy_count}コピー ・ {new Date(item.updated_at).toLocaleDateString("ja-JP")}</p>
              {(item.clear_titles?.length || 0) > 0 && <div className="clear-title-panel compact">{item.clear_titles?.slice(0,1).map((title) => <div key={title.name}><b><Trophy size={14} />デッキ完走称号</b><span>{title.name}</span><strong>{title.count}人</strong></div>)}</div>}
            </div>
          </Link>
          <div className="library-card-side">
            {item.content_type === "material" ? <BookOpen size={17} /> : <Layers3 size={17} />}
            <button onClick={() => copy(item)} className="primary-button"><BookCopy size={14} />コピー</button>
          </div>
        </article>)}
      </div>
      {!loading && !items.length && <div className="surface p-10 text-center mt-7"><b>該当する公開コンテンツはありません。</b></div>}
      {loading && <p className="text-sm text-[#71818d] mt-8">読み込み中...</p>}
    </div>
  </main></>;
}
