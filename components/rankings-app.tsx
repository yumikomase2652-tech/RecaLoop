"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { BookOpen, Clock3, Flame, Layers3, Medal, Trophy } from "lucide-react";
import { AppRouteNav } from "@/components/app-route-nav";
import { loadRankings } from "@/lib/recaloop-data";
import type { RankingItem } from "@/lib/types";

export function RankingsApp() {
  const [items, setItems] = useState<RankingItem[]>([]);
  const [error, setError] = useState("");
  useEffect(() => { loadRankings().then(setItems).catch((reason) => setError(reason.message)); }, []);
  const sections = [
    { title: "人気デッキ", icon: Trophy, items: [...items].sort((a, b) => b.copy_count - a.copy_count) },
    { title: "完走率が高い", icon: Medal, items: [...items].filter((item) => item.completion_rate !== null).sort((a, b) => (b.completion_rate || 0) - (a.completion_rate || 0)) },
    { title: "継続率が高い", icon: Flame, items: [...items].filter((item) => item.continuation_rate !== null).sort((a, b) => (b.continuation_rate || 0) - (a.continuation_rate || 0)) },
    { title: "最近コピーされた", icon: Clock3, items: [...items].sort((a, b) => new Date(b.last_copied_at || b.approved_at).getTime() - new Date(a.last_copied_at || a.approved_at).getTime()) },
  ];
  return <><AppRouteNav active="library" /><main className="app-page min-h-screen p-4 pb-28 md:p-10"><div className="max-w-6xl mx-auto">
    <Link href="/library" className="back-link">← 公開ライブラリ</Link>
    <p className="eyebrow mt-7">DECK RANKINGS</p><h1 className="text-3xl font-black mt-2">教材ランキング</h1>
    <p className="text-sm text-[#71818d] mt-2">個人を特定しない集計です。利用者が3人未満のデッキは進捗統計を表示しません。</p>
    {error && <p className="notice mt-5">{error}</p>}
    <div className="space-y-10 mt-8">{sections.map(({ title, icon: Icon, items: ranked }) => <section key={title}>
      <h2 className="font-black flex items-center gap-2"><Icon size={18} />{title}</h2>
      <div className="grid md:grid-cols-2 gap-4 mt-3">{ranked.slice(0, 6).map((item, index) => <article className="surface p-5" key={`${title}-${item.content_type}-${item.id}`}>
        <div className="flex justify-between"><span className="tag neutral">{item.content_type === "material" ? <><BookOpen size={12} />教材</> : <><Layers3 size={12} />暗記カード</>}</span><b className="text-sm text-[#9a7a24]">#{index + 1}</b></div>
        <h3 className="font-black mt-3">{item.title}</h3><p className="text-xs text-[#71818d] mt-1">作成者 {item.creator_name}</p>
        <div className="ranking-stats"><Stat label="コピー" value={item.copy_count} /><Stat label="平均進捗" value={percent(item.average_progress)} /><Stat label="完走率" value={percent(item.completion_rate)} /><Stat label="継続率" value={percent(item.continuation_rate)} /></div>
        {item.sample_count < 3 && <p className="text-[10px] text-[#8a98a1] mt-3">統計は利用者3人以上で公開されます</p>}
      </article>)}</div>
    </section>)}</div>
  </div></main></>;
}

const percent = (value: number | null) => value === null ? "非表示" : `${value}%`;
function Stat({ label, value }: { label: string; value: string | number }) { return <div><b>{value}</b><span>{label}</span></div>; }
