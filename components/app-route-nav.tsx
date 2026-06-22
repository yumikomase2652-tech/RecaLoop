"use client";

import Link from "next/link";
import { BookOpen, CalendarCheck, Home, Layers3, Library, Settings } from "lucide-react";

const items = [
  ["home", "ホーム", Home, "/dashboard?view=home"],
  ["reviews", "復習", CalendarCheck, "/dashboard?view=reviews"],
  ["materials", "教材", BookOpen, "/dashboard?view=materials"],
  ["words", "暗記", Layers3, "/dashboard?view=words"],
  ["library", "ライブラリ", Library, "/library"],
  ["settings", "設定", Settings, "/dashboard?view=settings"],
] as const;

export function AppRouteNav({ active }: { active: string }) {
  return <>
    <aside className="app-sidebar">
      <div className="mb-8"><b className="text-xl">RecaLoop</b><p className="text-[10px] text-[#718398]">個人学習用</p></div>
      {items.map(([id, label, Icon, href]) => <Link key={id} href={href} className={active === id ? "active" : ""}><Icon size={18} />{label}</Link>)}
    </aside>
    <nav className="bottom-nav" aria-label="メインメニュー">
      {items.map(([id, label, Icon, href]) => <Link key={id} href={href} aria-current={active === id ? "page" : undefined} className={active === id ? "active" : ""}><Icon size={20} /><span>{label}</span></Link>)}
    </nav>
  </>;
}
