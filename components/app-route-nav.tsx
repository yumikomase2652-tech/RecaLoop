"use client";

import Link from "next/link";
import { CalendarCheck, Home, Layers3, Library, Settings } from "lucide-react";

const items = [
  ["home", "ホーム", Home, "/dashboard?view=home"],
  ["reviews", "復習", CalendarCheck, "/dashboard?view=reviews"],
  ["decks", "デッキ", Layers3, "/dashboard?view=decks"],
  ["library", "ライブラリ", Library, "/library"],
  ["settings", "設定", Settings, "/dashboard?view=settings"],
] as const;

export function AppRouteNav({ active }: { active: string }) {
  return <>
    <aside className="app-sidebar">
      {items.map(([id, label, Icon, href]) => <Link key={id} href={href} className={active === id ? "active" : ""}><Icon size={18} />{label}</Link>)}
    </aside>
    <nav className="bottom-nav" aria-label="メインメニュー">
      {items.map(([id, label, Icon, href]) => <Link key={id} href={href} aria-label={label} title={label} aria-current={active === id ? "page" : undefined} className={active === id ? "active" : ""}><Icon size={20} /><span>{label}</span></Link>)}
    </nav>
  </>;
}
