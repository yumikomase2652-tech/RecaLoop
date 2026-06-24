"use client";

import Link from "next/link";
import { useEffect,useState } from "react";
import { CalendarDays,CalendarCheck,ClipboardList,Home,Layers3,Library,Settings,Users } from "lucide-react";
import { createClient,hasSupabaseEnv } from "@/lib/supabase/client";
import type { UserRole } from "@/lib/types";

const items = [
  ["home", "ホーム", Home, "/dashboard?view=home"],
  ["reviews", "復習", CalendarCheck, "/dashboard?view=reviews"],
  ["decks", "デッキ", Layers3, "/dashboard?view=decks"],
  ["calendar", "カレンダー", CalendarDays, "/dashboard?view=calendar"],
  ["library", "ライブラリ", Library, "/library"],
] as const;

export function AppRouteNav({ active }: { active: string }) {
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
    ? (["students", "生徒", Users, "/dashboard?view=students"] as const)
    : (["assignments", "課題", ClipboardList, "/dashboard?view=assignments"] as const);
  const navItems = [...items, roleItem, ["settings", "設定", Settings, "/dashboard?view=settings"] as const];
  return <>
    <aside className="app-sidebar">
      {navItems.map(([id, label, Icon, href]) => <Link key={id} href={href} className={active === id ? "active" : ""}><Icon size={18} />{label}</Link>)}
    </aside>
    <nav className="bottom-nav" aria-label="メインメニュー">
      {navItems.map(([id, label, Icon, href]) => <Link key={id} href={href} aria-label={label} title={label} aria-current={active === id ? "page" : undefined} className={active === id ? "active" : ""}><Icon size={20} /><span>{label}</span></Link>)}
    </nav>
  </>;
}
