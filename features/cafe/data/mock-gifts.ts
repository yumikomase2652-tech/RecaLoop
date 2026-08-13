import type { CafeGift } from "../types/cafe";

export const cafeGifts: CafeGift[] = [
  {
    id: "pressed-leaf",
    name: "押し葉のしおり",
    description: "こはくがたまに置いていく小さな思い出。",
    imageKey: "gift-pressed-leaf",
    fromVisitorId: "kohaku",
  },
  {
    id: "tiny-bean",
    name: "ちいさな豆袋",
    description: "常連さんからのありがとう。",
    imageKey: "gift-tiny-bean",
    fromVisitorId: "mugi",
  },
  {
    id: "blue-ticket",
    name: "青い来店券",
    description: "本好きのお客さんが残した小さなチケット。",
    imageKey: "gift-blue-ticket",
    fromVisitorId: "sumire",
  },
];
