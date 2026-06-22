"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { AlertTriangle, CheckCircle2, ShieldCheck, XCircle } from "lucide-react";
import { loadAdminContent, loadSubmissions, moderateSubmission } from "@/lib/recaloop-data";
import type { MaterialNode, SharedCards, SharedMaterial, Submission } from "@/lib/types";

const longText = (text?: string | null) => Boolean(text && text.length > 180);

export function AdminSubmissions() {
  const [items, setItems] = useState<Submission[]>([]);
  const [selected, setSelected] = useState<Submission | null>(null);
  const [detail, setDetail] = useState<SharedMaterial | SharedCards | null>(null);
  const [message, setMessage] = useState("");

  useEffect(() => {
    loadSubmissions().then(setItems).catch((error) => setMessage(error.message));
  }, []);

  const open = async (item: Submission) => {
    setSelected(item);
    setDetail(await loadAdminContent(item.content_type, item.id));
  };

  const moderate = async (approve: boolean) => {
    if (!selected) return;
    const reason = approve ? undefined : prompt("却下理由を入力してください")?.trim() || undefined;
    if (!approve && !reason) return;
    await moderateSubmission(selected.content_type, selected.id, approve, reason);
    setItems((current) => current.filter((item) => item.id !== selected.id || item.content_type !== selected.content_type));
    setSelected(null);
    setDetail(null);
    setMessage(approve ? "承認しました" : "却下理由を保存しました");
  };

  return <main className="min-h-screen p-4 md:p-10">
    <div className="max-w-6xl mx-auto">
      <header className="flex justify-between gap-4">
        <div><p className="eyebrow">ADMIN</p><h1 className="text-3xl font-black mt-2 flex items-center gap-2"><ShieldCheck />投稿申請</h1></div>
        <Link href="/dashboard" className="secondary-button self-start">マイページ</Link>
      </header>
      {message && <p className="notice mt-5">{message}</p>}
      <div className="grid md:grid-cols-[340px_1fr] gap-5 mt-7">
        <aside className="space-y-3">
          {items.map((item) => <button key={`${item.content_type}-${item.id}`} onClick={() => open(item)} className={`surface p-4 text-left w-full ${selected?.id === item.id ? "ring-2 ring-[#6da5c0]" : ""}`}>
            <div className="flex gap-2"><span className="tag neutral">{item.content_type === "material" ? "教材デッキ" : "暗記カード"}</span><span className="tag">{item.submission_kind === "update" ? "公開版更新" : "新規投稿"}</span></div>
            <b className="block mt-3">{item.title}</b>
            <p className="text-xs text-[#71818d] mt-1">{item.creator_name} ・ {item.item_count}件</p>
            <p className="text-[10px] text-[#71818d] mt-1">申請 {new Date(item.submitted_at).toLocaleString("ja-JP")}</p>
          </button>)}
          {!items.length && <div className="surface p-6 text-sm">申請はありません。</div>}
        </aside>
        <section>{selected && detail ? <div className="surface p-5 md:p-6">
          <div className="flex flex-wrap justify-between gap-3">
            <div><span className="tag">{selected.submission_kind === "update" ? "公開版の更新申請" : "新規掲載申請"}</span><h2 className="text-2xl font-black mt-3">{selected.title}</h2><p className="text-xs text-[#71818d] mt-2">作成者 {selected.creator_name} ・ {selected.item_count}件</p></div>
            <div className="flex gap-2"><button onClick={() => moderate(false)} className="secondary-button text-[#b34f4f]"><XCircle size={16} />却下</button><button onClick={() => moderate(true)} className="primary-button"><CheckCircle2 size={16} />承認</button></div>
          </div>
          <p className="notice mt-5 flex gap-2"><AlertTriangle size={16} className="shrink-0" />黄色の項目は180文字を超えています。教材本文・問題文・解答の転載でないか確認してください。</p>
          <div className="mt-6 border-t pt-5">{"nodes" in detail ? <AdminTree nodes={(detail as SharedMaterial).nodes} /> : <div className="divide-y">{(detail as SharedCards).cards.map((card) => <div className={`py-3 ${longText(card.front) || longText(card.back) || longText(card.memo) ? "long-content" : ""}`} key={card.id}>
            <b>{card.card_id && `${card.card_id} `}{card.front}</b><span className="char-count">front {card.front.length}字</span>
            <p className="text-sm mt-1">{card.back}</p><span className="char-count">back {card.back.length}字</span>
            {card.memo && <p className="text-xs text-[#71818d] mt-1">メモ: {card.memo} <span className="char-count">{card.memo.length}字</span></p>}
          </div>)}</div>}</div>
        </div> : <div className="surface p-10 text-center text-sm text-[#71818d]">左の申請を選択して内容を確認してください。</div>}</section>
      </div>
    </div>
  </main>;
}

function AdminTree({ nodes }: { nodes: MaterialNode[] }) {
  const render = (parent: string | null, depth: number): React.ReactNode => nodes.filter((node) => node.parent_id === parent).map((node) => <div key={node.id} className={`py-1.5 ${longText(node.memo) ? "long-content" : ""}`} style={{ paddingLeft: depth * 18 }}>
    <b className={node.node_type === "item" ? "text-sm" : ""}>{node.node_type === "folder" ? "› " : "・"}{node.title}</b>
    {node.memo && <span className="text-xs text-[#71818d] ml-2">{node.memo} <span className="char-count">{node.memo.length}字</span></span>}
    {node.node_type === "folder" && render(node.id, depth + 1)}
  </div>);
  return render(null, 0);
}
