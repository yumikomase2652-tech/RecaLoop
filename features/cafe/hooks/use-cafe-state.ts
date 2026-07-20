"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { defaultCafeState } from "../data/default-state";
import { cafeExpansions, cafeThemes } from "../data/mock-themes";
import { cafeItems } from "../data/mock-items";
import { cafeVisitors } from "../data/mock-visitors";
import type { CafePlacement, CafeState, CafeVisit } from "../types/cafe";

const storageKey = "recaloop-cafe-state-v1";
const stateEvent = "recaloop-cafe-state";

function safeState(input: unknown): CafeState {
  const value = input as Partial<CafeState> | null;
  return {
    ...defaultCafeState,
    ...value,
    ownedItemIds: [...new Set([...defaultCafeState.ownedItemIds, ...(value?.ownedItemIds || [])])],
    ownedThemeIds: [...new Set([...defaultCafeState.ownedThemeIds, ...(value?.ownedThemeIds || [])])],
    ownedExpansionIds: [...new Set([...defaultCafeState.ownedExpansionIds, ...(value?.ownedExpansionIds || [])])],
    placements: value?.placements || defaultCafeState.placements,
    visits: value?.visits || defaultCafeState.visits,
    gifts: value?.gifts || defaultCafeState.gifts,
    albumPhotos: value?.albumPhotos || defaultCafeState.albumPhotos,
  };
}

function loadCafeState() {
  if (typeof window === "undefined") return defaultCafeState;
  try {
    const raw = localStorage.getItem(storageKey);
    return raw ? safeState(JSON.parse(raw)) : defaultCafeState;
  } catch {
    return defaultCafeState;
  }
}

function saveCafeState(next: CafeState) {
  if (typeof window === "undefined") return;
  localStorage.setItem(storageKey, JSON.stringify(next));
  window.dispatchEvent(new CustomEvent(stateEvent, { detail: next }));
}

function seededNumber(seed: string) {
  let hash = 2166136261;
  for (let index = 0; index < seed.length; index++) {
    hash ^= seed.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return Math.abs(hash >>> 0);
}

function rewardFor(visitorId: string, seed: string) {
  const visitor = cafeVisitors.find((item) => item.id === visitorId) || cafeVisitors[0];
  const span = visitor.rewardCoinsMax - visitor.rewardCoinsMin + 1;
  return visitor.rewardCoinsMin + (seededNumber(`${visitorId}:${seed}`) % span);
}

function eligibleVisitors(state: CafeState) {
  const itemIds = new Set(state.placements.map((placement) => placement.itemId));
  return cafeVisitors.filter((visitor) => {
    if (visitor.unlockCondition?.requiredExpansionId && state.activeExpansionId !== visitor.unlockCondition.requiredExpansionId) return false;
    if (!visitor.preferredItemIds.length) return true;
    return visitor.preferredItemIds.some((id) => itemIds.has(id));
  });
}

function simulateVisits(input: CafeState) {
  const last = new Date(input.lastVisitSimulationAt).getTime();
  const now = Date.now();
  if (!Number.isFinite(last) || now - last < 60 * 60 * 1000) return input;

  const elapsedHours = Math.min(12, Math.floor((now - last) / (60 * 60 * 1000)));
  if (elapsedHours <= 0) return input;

  const activeExpansion = cafeExpansions.find((expansion) => expansion.id === input.activeExpansionId) || cafeExpansions[0];
  const visitors = eligibleVisitors(input);
  const existingOpen = input.visits.filter((visit) => !visit.rewardClaimedAt && new Date(visit.endedAt).getTime() > now).length;
  const room = Math.max(0, activeExpansion.maxVisitors - existingOpen);
  const visitCount = Math.min(room, Math.max(1, Math.floor(elapsedHours / 3)));
  const nextVisits: CafeVisit[] = [];

  for (let index = 0; index < visitCount; index++) {
    const seed = `${input.lastVisitSimulationAt}:${index}:${input.activeThemeId}:${input.activeExpansionId}`;
    const visitor = visitors[seededNumber(seed) % visitors.length] || cafeVisitors[0];
    const usedItemId = visitor.preferredItemIds.find((id) => input.placements.some((placement) => placement.itemId === id));
    const started = new Date(now - (visitCount - index) * 18 * 60 * 1000);
    const ended = new Date(started.getTime() + visitor.visitDurationMinutes * 60 * 1000);
    nextVisits.push({
      id: `visit-${seededNumber(seed)}-${now}`,
      visitorId: visitor.id,
      usedItemId,
      startedAt: started.toISOString(),
      endedAt: ended.toISOString(),
      rewardCoins: rewardFor(visitor.id, seed),
      photoKey: `auto-${visitor.id}`,
    });
  }

  return {
    ...input,
    visits: [...nextVisits, ...input.visits].slice(0, 80),
    lastVisitSimulationAt: new Date(now).toISOString(),
  };
}

export function useCafeState() {
  const [state, setState] = useState<CafeState>(() => loadCafeState());

  const commit = useCallback((updater: (current: CafeState) => CafeState) => {
    setState((current) => {
      const next = safeState(updater(current));
      saveCafeState(next);
      return next;
    });
  }, []);

  useEffect(() => {
    const onState = (event: Event) => {
      const detail = (event as CustomEvent<CafeState>).detail;
      if (detail) setState(safeState(detail));
    };
    window.addEventListener(stateEvent, onState);
    return () => window.removeEventListener(stateEvent, onState);
  }, []);

  useEffect(() => {
    commit(simulateVisits);
  }, [commit]);

  const activeTheme = cafeThemes.find((theme) => theme.id === state.activeThemeId) || cafeThemes[0];
  const activeExpansion = cafeExpansions.find((expansion) => expansion.id === state.activeExpansionId) || cafeExpansions[0];
  const ownedItems = useMemo(() => cafeItems.filter((item) => state.ownedItemIds.includes(item.id)), [state.ownedItemIds]);
  const currentVisits = useMemo(() => state.visits.filter((visit) => new Date(visit.endedAt).getTime() > Date.now()), [state.visits]);
  const claimableVisits = useMemo(() => state.visits.filter((visit) => new Date(visit.endedAt).getTime() <= Date.now() && !visit.rewardClaimedAt), [state.visits]);

  const placeItem = useCallback((slotId: string, itemId: string | null) => {
    commit((current) => ({
      ...current,
      placements: itemId
        ? [...current.placements.filter((placement) => placement.slotId !== slotId), { slotId, itemId }]
        : current.placements.filter((placement) => placement.slotId !== slotId),
    }));
  }, [commit]);

  const savePlacements = useCallback((placements: CafePlacement[]) => {
    commit((current) => ({ ...current, placements }));
  }, [commit]);

  const buyItem = useCallback((itemId: string) => {
    const item = cafeItems.find((candidate) => candidate.id === itemId);
    if (!item) return "商品が見つかりません。";
    if (state.ownedItemIds.includes(itemId)) return "すでに購入済みです。";
    if (state.coins < item.price) return "コインが足りません。";
    if (item.unlockCondition?.requiredExpansionId && !state.ownedExpansionIds.includes(item.unlockCondition.requiredExpansionId)) return "Cafe拡張後に購入できます。";
    commit((current) => ({ ...current, coins: current.coins - item.price, ownedItemIds: [...current.ownedItemIds, itemId] }));
    return "";
  }, [commit, state.coins, state.ownedExpansionIds, state.ownedItemIds]);

  const buyTheme = useCallback((themeId: string) => {
    const theme = cafeThemes.find((candidate) => candidate.id === themeId);
    if (!theme) return "テーマが見つかりません。";
    if (state.ownedThemeIds.includes(themeId)) {
      commit((current) => ({ ...current, activeThemeId: themeId }));
      return "";
    }
    if (theme.availableAfterExpansion && !state.ownedExpansionIds.includes(theme.availableAfterExpansion)) return "Cafe拡張後に購入できます。";
    if (state.coins < theme.price) return "コインが足りません。";
    commit((current) => ({ ...current, coins: current.coins - theme.price, activeThemeId: themeId, ownedThemeIds: [...current.ownedThemeIds, themeId] }));
    return "";
  }, [commit, state.coins, state.ownedExpansionIds, state.ownedThemeIds]);

  const buyExpansion = useCallback((expansionId: string) => {
    const expansion = cafeExpansions.find((candidate) => candidate.id === expansionId);
    if (!expansion) return "拡張が見つかりません。";
    if (state.ownedExpansionIds.includes(expansionId)) {
      commit((current) => ({ ...current, activeExpansionId: expansionId }));
      return "";
    }
    if (state.coins < expansion.price) return "コインが足りません。";
    commit((current) => ({ ...current, coins: current.coins - expansion.price, activeExpansionId: expansionId, ownedExpansionIds: [...current.ownedExpansionIds, expansionId] }));
    return "";
  }, [commit, state.coins, state.ownedExpansionIds]);

  const claimRewards = useCallback((visitIds?: string[]) => {
    const allowed = new Set(visitIds);
    commit((current) => {
      let gained = 0;
      const visits = current.visits.map((visit) => {
        const target = !visit.rewardClaimedAt && new Date(visit.endedAt).getTime() <= Date.now() && (!visitIds || allowed.has(visit.id));
        if (!target) return visit;
        gained += visit.rewardCoins;
        return { ...visit, rewardClaimedAt: new Date().toISOString() };
      });
      return { ...current, coins: current.coins + gained, visits };
    });
  }, [commit]);

  const switchTheme = useCallback((themeId: string) => {
    commit((current) => current.ownedThemeIds.includes(themeId) ? { ...current, activeThemeId: themeId } : current);
  }, [commit]);

  const switchExpansion = useCallback((expansionId: string) => {
    commit((current) => current.ownedExpansionIds.includes(expansionId) ? { ...current, activeExpansionId: expansionId } : current);
  }, [commit]);

  return {
    state,
    activeTheme,
    activeExpansion,
    ownedItems,
    currentVisits,
    claimableVisits,
    placeItem,
    savePlacements,
    buyItem,
    buyTheme,
    buyExpansion,
    claimRewards,
    switchTheme,
    switchExpansion,
  };
}
