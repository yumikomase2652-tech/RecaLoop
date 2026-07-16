"use client";

import Link from "next/link";
import { useEffect,useState } from "react";
import { Bell,ChartNoAxesColumnIncreasing,Clock3,Coffee,Home,Layers3,Settings } from "lucide-react";
import { createClient,hasSupabaseEnv } from "@/lib/supabase/client";
import type { UserRole } from "@/lib/types";

const items = [
  ["home", "ホーム", Home, "/dashboard?view=home"],
  ["study", "学習", Clock3, "/dashboard?view=study"],
  ["materials", "教材", Layers3, "/dashboard?view=materials"],
  ["progress", "進捗", ChartNoAxesColumnIncreasing, "/dashboard?view=progress"],
  ["cafe", "カフェ", Coffee, "/dashboard?view=cafe"],
] as const;

export function AppRouteNav({ active }: { active: string }) {
  const activeId = active === "library" || active === "rankings" ? "materials" : active;
  const [role, setRole] = useState<UserRole>(() => {
    if (typeof window === "undefined") return "none";
    return (localStorage.getItem("recaloop-role") as UserRole) || "none";
  });
  useEffect(() => {
    if (!hasSupabaseEnv) return;
    createClient().from("profiles").select("role").maybeSingle().then(({ data }) => {
      const next = (data?.role as UserRole) || "none";
      setRole(next);
      try { localStorage.setItem("recaloop-role", next); } catch {}
    });
  }, []);
  const roleItem = role === "teacher"
    ? (["students", "生徒", "/dashboard?view=students"] as const)
    : role === "student"
      ? (["assignments", "課題", "/dashboard?view=assignments"] as const)
      : null;
  return <>
    <aside className="app-sidebar">
      {items.map(([id, label, Icon, href]) => <Link key={id} href={href} className={activeId === id ? "active" : ""}><Icon size={18} />{label}</Link>)}
      <div className="sidebar-mini-links">
        <Link href="/dashboard?view=notices" className={activeId === "notices" ? "active" : ""}><Bell size={16} />お知らせ</Link>
        {roleItem && <Link href={roleItem[2]} className={activeId === roleItem[0] ? "active" : ""}>{roleItem[1]}</Link>}
        <Link href="/dashboard?view=settings" className={activeId === "settings" ? "active" : ""}><Settings size={16} />設定</Link>
      </div>
    </aside>
    <nav className="bottom-nav" aria-label="メインメニュー">
      {items.map(([id, label, Icon, href]) => <Link key={id} href={href} aria-label={label} title={label} aria-current={activeId === id ? "page" : undefined} className={activeId === id ? "active" : ""}><Icon size={20} /><span>{label}</span></Link>)}
    </nav>
  </>;
}
