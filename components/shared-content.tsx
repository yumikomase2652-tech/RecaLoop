"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { BookCopy, ChevronRight, Layers3, Sparkles } from "lucide-react";
import { copySharedCards, copySharedMaterial, loadSharedCards, loadSharedMaterial } from "@/lib/recaloop-data";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/client";
import type { MaterialNode, SharedCards, SharedMaterial } from "@/lib/types";

export function SharedContent({ type, token }: { type: "material" | "cards"; token: string }) {
  const [data, setData] = useState<SharedMaterial | SharedCards | null | undefined>(undefined);
  const [message, setMessage] = useState("");

  useEffect(() => {
    (type === "material" ? loadSharedMaterial(token) : loadSharedCards(token))
      .then(setData)
      .catch((error) => setMessage(error.message));
  }, [token, type]);

  const copy = async () => {
    if (hasSupabaseEnv) {
      const { data: { user } } = await createClient().auth.getUser();
      if (!user) {
        location.href = "/login";
        return;
      }
    }
    try {
      if (type === "material") await copySharedMaterial(token);
      else await copySharedCards(token);
      location.href = "/dashboard";
    } catch (error) {
      setMessage((error as Error).message);
    }
  };

  if (data === undefined) return <Frame><p>読み込み中...</p></Frame>;
  if (!data) return <Frame><h1 className="text-2xl font-black">配布リンクが無効です</h1><p className="text-sm text-[#718398] mt-2">配布が停止されたか、URLが正しくありません。</p></Frame>;

  const source = type === "material" ? (data as SharedMaterial).deck : (data as SharedCards).list;
  const title = source.title;
  const approved = source.visibility === "approved";
  return <Frame>
    <div className="flex flex-wrap justify-between gap-4 items-end">
      <div>
        <span className="tag">{approved ? "公開ライブラリ" : "個別配布"}</span>
        <h1 className="text-3xl font-black mt-3">{title}</h1>
        <p className="text-sm text-[#718398] mt-2">{approved ? "運営が承認した公開コンテンツです" : `${type === "material" ? "教材デッキ" : "暗記カード"}の配布リンクです`}</p>
      </div>
      <button onClick={copy} className="primary-button"><BookCopy size={17} />自分のデッキにコピー</button>
    </div>
    <p className="notice mt-4">構造とカード内容だけをコピーします。作成者の評価履歴・チェック・復習状態は含まれません。</p>
    {message && <p className="notice mt-4">{message}</p>}
    <div className="surface p-5 mt-6">
      {type === "material" ? <SharedTree nodes={(data as SharedMaterial).nodes} /> : <div className="divide-y divide-[#e7ecef]">
        {(data as SharedCards).cards.map((card) => <div className="py-4" key={card.id}>
          <div className="flex gap-2 items-center">{card.card_id && <span className="tag neutral">{card.card_id}</span>}<b>{card.front}</b></div>
          <p className="mt-2">{card.back}</p>
          {card.memo && <p className="text-xs text-[#788794] mt-1">{card.memo}</p>}
        </div>)}
      </div>}
    </div>
  </Frame>;
}

function SharedTree({ nodes }: { nodes: MaterialNode[] }) {
  const render = (parent: string | null, depth: number): React.ReactNode => nodes.filter((node) => node.parent_id === parent).map((node) => <div key={node.id} className="py-2" style={{ paddingLeft: depth * 18 }}>
    <div className="flex items-center gap-2">{node.node_type === "folder" ? <ChevronRight size={15} className="text-[#8ba0af]" /> : <Layers3 size={14} className="text-[#3f8fb8]" />}<b className={node.node_type === "item" ? "text-sm" : ""}>{node.title}</b></div>
    {node.memo && <p className="text-xs text-[#788794] ml-6">{node.memo}</p>}
    {node.node_type === "folder" && render(node.id, depth + 1)}
  </div>);
  return render(null, 0);
}

function Frame({ children }: { children: React.ReactNode }) {
  return <main className="min-h-screen bg-[#f4f7f8] p-4 md:p-10"><div className="max-w-3xl mx-auto"><Link href="/" className="inline-flex items-center gap-2 font-black"><Sparkles size={20} className="text-[#3f8fb8]" />RecaLoop</Link><div className="mt-10">{children}</div></div></main>;
}
