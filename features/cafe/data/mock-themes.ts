import type { CafeExpansion, CafeTheme } from "../types/cafe";

export const cafeThemes: CafeTheme[] = [
  {
    id: "classic-coffee",
    name: "Classic Coffee",
    description: "最初から使える、木目とやわらかい灯りの小さなCafe。",
    price: 0,
    thumbnailKey: "theme-classic-thumb",
    sceneBackgroundKey: "theme-classic-bg",
    slotLayoutId: "compact",
  },
  {
    id: "forest-window",
    name: "Forest",
    description: "緑の窓辺がある静かなCafeテーマ。",
    price: 160,
    thumbnailKey: "theme-forest-thumb",
    sceneBackgroundKey: "theme-forest-bg",
    slotLayoutId: "compact",
  },
  {
    id: "night-cafe",
    name: "Night Café",
    description: "夜の読書に合う、落ち着いたCafeテーマ。",
    price: 220,
    thumbnailKey: "theme-night-thumb",
    sceneBackgroundKey: "theme-night-bg",
    slotLayoutId: "compact",
    availableAfterExpansion: "wide-room",
  },
];

export const cafeExpansions: CafeExpansion[] = [
  { id: "tiny-room", name: "小さいCafe", price: 0, slotLayoutId: "compact", maxVisitors: 2 },
  { id: "wide-room", name: "Cafe拡張", price: 300, slotLayoutId: "expanded", maxVisitors: 4 },
];
