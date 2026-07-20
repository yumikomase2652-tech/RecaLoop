import type { CafeState } from "../types/cafe";

export const defaultCafeState: CafeState = {
  coins: 420,
  activeThemeId: "classic-coffee",
  activeExpansionId: "tiny-room",
  ownedItemIds: ["round-table", "coffee-set"],
  ownedThemeIds: ["classic-coffee"],
  ownedExpansionIds: ["tiny-room", "wide-room"],
  placements: [
    { slotId: "small_01", itemId: "round-table" },
    { slotId: "food_01", itemId: "coffee-set" },
  ],
  visits: [
    {
      id: "visit-initial-mugi",
      visitorId: "mugi",
      usedItemId: "round-table",
      startedAt: new Date(Date.now() - 24 * 60 * 1000).toISOString(),
      endedAt: new Date(Date.now() + 21 * 60 * 1000).toISOString(),
      rewardCoins: 12,
    },
  ],
  gifts: [],
  albumPhotos: [
    {
      id: "photo-first-day",
      title: "開店準備の日",
      createdAt: new Date().toISOString(),
      visitorIds: ["mugi"],
      themeId: "classic-coffee",
    },
  ],
  lastVisitSimulationAt: new Date().toISOString(),
};
