"use client";

import { useEffect, useMemo, useState } from "react";
import { ChevronLeft, Coffee, Pause, Play, RotateCcw, Timer } from "lucide-react";
import { CafeRoot } from "@/features/cafe/screens/cafe-root";
import styles from "./study-timer.module.css";

type TimerMode = "digital" | "visual" | "cafe";

export function StudyTimer({ back }: { back: () => void }) {
  const [mode, setMode] = useState<TimerMode>("digital");
  const [running, setRunning] = useState(false);
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    if (!running) return;
    const id = window.setInterval(() => setElapsed((current) => current + 1), 1000);
    return () => window.clearInterval(id);
  }, [running]);

  const display = useMemo(() => {
    const hours = Math.floor(elapsed / 3600);
    const minutes = Math.floor((elapsed % 3600) / 60);
    const seconds = elapsed % 60;
    return hours
      ? `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`
      : `${pad(minutes)}:${pad(seconds)}`;
  }, [elapsed]);

  const progress = Math.min(1, (elapsed % 1500) / 1500);

  return (
    <div className={styles.screen}>
      <header className={styles.header}>
        <button type="button" onClick={back} aria-label="戻る"><ChevronLeft size={25} /></button>
        <h1>タイマー</h1>
        <span />
      </header>
      <div className={styles.segmented} role="tablist" aria-label="タイマー表示">
        {(["digital", "visual", "cafe"] as const).map((item) => (
          <button key={item} type="button" data-active={mode === item} onClick={() => setMode(item)}>
            {item === "digital" ? "デジタル" : item === "visual" ? "ビジュアル" : "カフェ"}
          </button>
        ))}
      </div>
      <section className={styles.timerCard} data-mode={mode}>
        {mode === "digital" && (
          <div className={styles.digitalFace}>
            <Timer size={30} />
            <strong>{display}</strong>
            <span>集中時間</span>
          </div>
        )}
        {mode === "visual" && (
          <div className={styles.visualFace}>
            <svg viewBox="0 0 180 180" aria-hidden="true">
              <circle cx="90" cy="90" r="72" />
              <circle cx="90" cy="90" r="72" style={{ strokeDashoffset: `${452 - 452 * progress}` }} />
            </svg>
            <strong>{display}</strong>
          </div>
        )}
        {mode === "cafe" && (
          <div className={styles.cafeFace}>
            <CafeRoot compact />
            <b>{display}</b>
          </div>
        )}
      </section>
      <footer className={styles.controls}>
        <button className={styles.resetButton} type="button" onClick={() => { setRunning(false); setElapsed(0); }}>
          <RotateCcw size={20} />
          リセット
        </button>
        <button className={styles.mainButton} type="button" onClick={() => setRunning((value) => !value)}>
          {running ? <Pause size={22} /> : <Play size={22} />}
          {running ? "ストップ" : "スタート"}
        </button>
        <span className={styles.coffeeMark}><Coffee size={20} /></span>
      </footer>
    </div>
  );
}

function pad(value: number) {
  return String(value).padStart(2, "0");
}
