export type CafeScreen = "home" | "goods" | "shop" | "visitors" | "album" | "gifts" | "menu";

export type CafeSceneMode = "full" | "preview" | "editor";

export type PlacementSize = "small" | "large" | "food" | "wall";

export type CafeItemCategory = "furniture" | "food" | "drink" | "decoration" | "wall" | "floor";

export type UnlockCondition = {
  minStudyMinutesToday?: number;
  minQuestionCountToday?: number;
  requiredExpansionId?: string;
};

export type CafeSlot = {
  id: string;
  type: PlacementSize;
  xPercent: number;
  yPercent: number;
  widthPercent: number;
  heightPercent: number;
  zIndex: number;
};

export type CafeItem = {
  id: string;
  name: string;
  description: string;
  category: CafeItemCategory;
  imageKey: string;
  price: number;
  placementSize: PlacementSize;
  themeIds?: string[];
  visitorTags: string[];
  unlockCondition?: UnlockCondition;
};

export type CafeTheme = {
  id: string;
  name: string;
  description: string;
  price: number;
  thumbnailKey: string;
  sceneBackgroundKey: string;
  sceneForegroundKey?: string;
  slotLayoutId: string;
  availableAfterExpansion?: string;
};

export type CafeExpansion = {
  id: string;
  name: string;
  price: number;
  slotLayoutId: string;
  maxVisitors: number;
  unlockCondition?: UnlockCondition;
};

export type CafeVisitor = {
  id: string;
  name: string;
  description: string;
  imageKey: string;
  rarity: "common" | "rare" | "special";
  preferredItemIds: string[];
  preferredTags: string[];
  rewardCoinsMin: number;
  rewardCoinsMax: number;
  visitDurationMinutes: number;
  unlockCondition?: UnlockCondition;
  specialGiftId?: string;
};

export type CafeGift = {
  id: string;
  name: string;
  description: string;
  imageKey: string;
  fromVisitorId?: string;
};

export type CafeVisit = {
  id: string;
  visitorId: string;
  usedItemId?: string;
  startedAt: string;
  endedAt: string;
  rewardCoins: number;
  rewardClaimedAt?: string;
  photoKey?: string;
};

export type CafePlacement = {
  slotId: string;
  itemId: string;
};

export type CafeAlbumPhoto = {
  id: string;
  title: string;
  createdAt: string;
  visitorIds: string[];
  themeId: string;
};

export type CafeState = {
  coins: number;
  activeThemeId: string;
  activeExpansionId: string;
  ownedItemIds: string[];
  ownedThemeIds: string[];
  ownedExpansionIds: string[];
  placements: CafePlacement[];
  visits: CafeVisit[];
  gifts: string[];
  albumPhotos: CafeAlbumPhoto[];
  lastVisitSimulationAt: string;
};
