import type { CafeSlot } from "../types/cafe";

export const cafeSlotLayouts: Record<string, CafeSlot[]> = {
  compact: [
    { id: "wall_01", type: "wall", xPercent: 15, yPercent: 16, widthPercent: 20, heightPercent: 18, zIndex: 1 },
    { id: "small_01", type: "small", xPercent: 12, yPercent: 56, widthPercent: 18, heightPercent: 18, zIndex: 6 },
    { id: "small_02", type: "small", xPercent: 38, yPercent: 57, widthPercent: 18, heightPercent: 18, zIndex: 7 },
    { id: "food_01", type: "food", xPercent: 64, yPercent: 62, widthPercent: 18, heightPercent: 13, zIndex: 9 },
  ],
  expanded: [
    { id: "wall_01", type: "wall", xPercent: 12, yPercent: 15, widthPercent: 18, heightPercent: 18, zIndex: 1 },
    { id: "wall_02", type: "wall", xPercent: 62, yPercent: 14, widthPercent: 18, heightPercent: 18, zIndex: 1 },
    { id: "large_01", type: "large", xPercent: 8, yPercent: 54, widthPercent: 30, heightPercent: 24, zIndex: 5 },
    { id: "small_01", type: "small", xPercent: 43, yPercent: 57, widthPercent: 16, heightPercent: 17, zIndex: 7 },
    { id: "small_02", type: "small", xPercent: 61, yPercent: 55, widthPercent: 16, heightPercent: 17, zIndex: 7 },
    { id: "small_03", type: "small", xPercent: 78, yPercent: 57, widthPercent: 15, heightPercent: 16, zIndex: 8 },
    { id: "food_01", type: "food", xPercent: 48, yPercent: 73, widthPercent: 15, heightPercent: 12, zIndex: 10 },
    { id: "food_02", type: "food", xPercent: 70, yPercent: 72, widthPercent: 15, heightPercent: 12, zIndex: 10 },
  ],
};
