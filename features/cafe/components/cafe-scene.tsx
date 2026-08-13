"use client";

import { cafeItems } from "../data/mock-items";
import { cafeSlotLayouts } from "../data/mock-slots";
import { cafeVisitors } from "../data/mock-visitors";
import type { CafePlacement, CafeSceneMode, CafeSlot, CafeTheme, CafeVisit } from "../types/cafe";
import styles from "./cafe.module.css";

type CafeSceneProps = {
  mode: CafeSceneMode;
  theme: CafeTheme;
  slotLayoutId: string;
  placements: CafePlacement[];
  visits?: CafeVisit[];
  selectedSlotId?: string | null;
  onSelectSlot?: (slot: CafeSlot) => void;
};

function positionStyle(slot: CafeSlot) {
  return {
    left: `${slot.xPercent}%`,
    top: `${slot.yPercent}%`,
    width: `${slot.widthPercent}%`,
    height: `${slot.heightPercent}%`,
    zIndex: slot.zIndex,
  };
}

function visitorPosition(index: number) {
  const points = [
    { left: "30%", top: "61%", zIndex: 15 },
    { left: "56%", top: "58%", zIndex: 16 },
    { left: "71%", top: "61%", zIndex: 17 },
    { left: "42%", top: "68%", zIndex: 18 },
  ];
  return points[index % points.length];
}

export function CafeScene({ mode, theme, slotLayoutId, placements, visits = [], selectedSlotId, onSelectSlot }: CafeSceneProps) {
  const slots = cafeSlotLayouts[slotLayoutId] || cafeSlotLayouts.compact;
  const visibleVisits = visits.filter((visit) => new Date(visit.endedAt).getTime() > Date.now()).slice(0, mode === "preview" ? 2 : 4);

  return (
    <div className={styles.sceneFrame} data-mode={mode} data-theme={theme.id} aria-label={`${theme.name}のCafe`}>
      <div className={styles.backgroundLayer} />
      <div className={styles.wallLayer}>
        <span className={styles.window} />
        <span className={styles.lamp} />
        <span className={styles.wallTrim} />
      </div>
      <div className={styles.backLayer}>
        <span className={styles.rug} />
      </div>
      <div className={styles.visitorLayer}>
        {visibleVisits.map((visit, index) => {
          const visitor = cafeVisitors.find((item) => item.id === visit.visitorId);
          if (!visitor) return null;
          return (
            <div className={styles.visitor} key={visit.id} style={visitorPosition(index)}>
              <span className={styles.visitorVisual} data-key={visitor.imageKey} />
              {mode !== "preview" && <span className={styles.visitorName}>{visitor.name}</span>}
            </div>
          );
        })}
      </div>
      <div className={styles.frontLayer}>
        {placements.map((placement) => {
          const slot = slots.find((candidate) => candidate.id === placement.slotId);
          const item = cafeItems.find((candidate) => candidate.id === placement.itemId);
          if (!slot || !item) return null;
          return (
            <div className={styles.placedItem} key={`${placement.slotId}:${placement.itemId}`} style={positionStyle(slot)}>
              <span className={styles.itemVisual} data-key={item.imageKey} />
              {mode === "editor" && <span className={styles.itemName}>{item.name}</span>}
            </div>
          );
        })}
      </div>
      <div className={styles.effectLayer}>
        <span className={styles.counter} />
      </div>
      {mode === "editor" && (
        <div className={styles.slotLayer}>
          {slots.map((slot) => (
            <button
              className={styles.slotButton}
              data-selected={selectedSlotId === slot.id}
              key={slot.id}
              style={positionStyle(slot)}
              type="button"
              onClick={() => onSelectSlot?.(slot)}
            >
              {slot.id.replace("_", " ")}
            </button>
          ))}
        </div>
      )}
      <div className={styles.foregroundLayer} />
    </div>
  );
}
