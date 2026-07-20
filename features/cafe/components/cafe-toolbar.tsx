"use client";

import { Gift, Home, Images, PackageOpen, ShoppingBag, Users } from "lucide-react";
import type { ElementType } from "react";
import type { CafeScreen } from "../types/cafe";
import styles from "./cafe.module.css";

const tabs: { id: CafeScreen; label: string; icon: ElementType }[] = [
  { id: "home", label: "Cafe", icon: Home },
  { id: "goods", label: "Goods", icon: PackageOpen },
  { id: "shop", label: "Shop", icon: ShoppingBag },
  { id: "visitors", label: "Visitors", icon: Users },
  { id: "album", label: "Album", icon: Images },
  { id: "gifts", label: "Gifts", icon: Gift },
];

export function CafeToolbar({ screen, setScreen }: { screen: CafeScreen; setScreen: (screen: CafeScreen) => void }) {
  return (
    <nav className={styles.toolbar} aria-label="Cafe navigation">
      {tabs.map(({ id, label, icon: Icon }) => (
        <button key={id} type="button" data-active={screen === id} onClick={() => setScreen(id)}>
          <Icon size={18} />
          {label}
        </button>
      ))}
    </nav>
  );
}
