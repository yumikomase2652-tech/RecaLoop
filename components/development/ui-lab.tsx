"use client";

import { useEffect, useMemo, useState } from "react";
import { ArrowUpDown, Bell, BookOpen, CalendarDays, ChevronLeft, Coffee, Ellipsis, Grid2X2, Plus, RotateCcw, Search, Settings, Timer } from "lucide-react";
import { ShopCard } from "@/components/cafe/shop-card";
import { UiBottomSheet } from "@/components/ui/bottom-sheet";
import { UiButton } from "@/components/ui/button";
import { UiCard } from "@/components/ui/card";
import { UiEmptyState } from "@/components/ui/empty-state";
import { UiIconButton } from "@/components/ui/icon-button";
import { UiListRow } from "@/components/ui/list-row";
import { UiLoadingOverlay } from "@/components/ui/loading-overlay";
import { UiPageHeader } from "@/components/ui/page-header";
import { UiSearchField } from "@/components/ui/search-field";
import { UiSection } from "@/components/ui/section";
import { UiSegmentedControl } from "@/components/ui/segmented-control";
import { UiToggle } from "@/components/ui/toggle";
import { MaterialGalleryCard } from "@/components/study/material-gallery-card";
import { MaterialListRow } from "@/components/study/material-list-row";
import { RatingButtons } from "@/components/study/rating-buttons";
import { StudyActionGrid } from "@/components/study/study-action-grid";
import { defaultUiTokens, tokensToCssVariables, type UiTokens } from "@/lib/ui-tokens";
import { TokenControlPanel } from "./token-control-panel";
import styles from "./ui-lab.module.css";

const storageKey = "recaloop-ui-lab-tokens";
const devices = [
  ["320px", 320],
  ["375px", 375],
  ["390px", 390],
  ["430px", 430],
  ["768px", 768],
  ["PC", 1040],
] as const;

const sampleMaterials = [
  { title: "改訂版 チャート式 基礎からの数学", count: "2,200枚", progress: "68%", due: "今日12件" },
  { title: "英単語ターゲット1900 長い教材名テスト", count: "1,900枚", progress: "34%", due: "期限なし" },
  { title: "数IA", count: "320枚", progress: "100%", due: "完了" },
  { title: "フォルダ：高校数学", count: "4教材", progress: "-", due: "フォルダ", folder: true },
];

export function UiLab() {
  const [tokens, setTokensState] = useState<UiTokens>(defaultUiTokens);
  const [deviceWidth, setDeviceWidth] = useState<number>(375);
  const [viewMode, setViewMode] = useState<"gallery" | "list">("gallery");
  const [sheetOpen, setSheetOpen] = useState(false);
  const [toggle, setToggle] = useState(true);
  const [copied, setCopied] = useState("");

  useEffect(() => {
    try {
      const saved = localStorage.getItem(storageKey);
      if (saved) setTokensState({ ...defaultUiTokens, ...JSON.parse(saved) });
    } catch {}
  }, []);

  const setTokens = (next: UiTokens) => {
    setTokensState(next);
    try {
      localStorage.setItem(storageKey, JSON.stringify(next));
    } catch {}
  };

  const style = useMemo(() => tokensToCssVariables(tokens) as React.CSSProperties, [tokens]);

  return (
    <main className={styles.page} style={style}>
      <TokenControlPanel tokens={tokens} setTokens={setTokens} copied={copied} setCopied={setCopied} />
      <div className={styles.workspace}>
        <header className={styles.hero}>
          <p>Development only</p>
          <h1>RecaLoop UI Lab</h1>
          <span>共通UI・トークン・Home/Studyモックを調整するための開発用画面です。本番画面の保存処理には接続していません。</span>
        </header>

        <section className={styles.deviceTools}>
          <b>Device Preview</b>
          <div>
            {devices.map(([label, width]) => (
              <button key={label} className={deviceWidth === width ? styles.active : ""} onClick={() => setDeviceWidth(width)}>
                {label}
              </button>
            ))}
          </div>
        </section>

        <div className={styles.deviceFrame} style={{ width: Math.min(deviceWidth, 1040) }}>
          <UiPageHeader
            title="UI Lab"
            large={deviceWidth > 430}
            subtitle="320pxからPC幅まで確認できます"
            back={() => {}}
            action={<UiIconButton label="設定" icon={<Settings size={20} />} />}
          />

          <UiSection title="Home Mock" footer="統計や教材一覧は置かず、ショップカードと学習アクションに絞った状態です。">
            <ShopCard nickname="いちご" handle="@hortus_long_id" grade="高校2年生" minutes="45分" questions="126問" />
            <StudyActionGrid scheduleCount={0} reviewCount={999} lastMaterial={{ title: "改訂版 チャート式 基礎からの数学", progress: 68 }} />
          </UiSection>

          <UiSection title="Study Mock" action={<UiButton variant="text" size="compact">教材</UiButton>}>
            <StudyActionGrid scheduleCount={12} reviewCount={3} lastMaterial={null} />
            <div className={styles.materialHeader}>
              <h3>教材</h3>
              <UiSearchField placeholder="検索" />
              <UiIconButton label="並べ替え" icon={<ArrowUpDown size={18} />} />
              <UiIconButton label="追加" icon={<Plus size={18} />} />
            </div>
            <UiSegmentedControl value={viewMode} options={["gallery", "list"] as const} labels={{ gallery: "ギャラリー", list: "リスト" }} onChange={setViewMode} />
            {viewMode === "gallery" ? (
              <div className={styles.galleryGrid}>
                {sampleMaterials.map((item) => (
                  <MaterialGalleryCard key={item.title} title={item.title} progress={item.folder ? undefined : Number(item.progress.replace("%", ""))} folder={item.folder} />
                ))}
              </div>
            ) : (
              <div className={styles.listGroup}>
                {sampleMaterials.map((item) => (
                  <MaterialListRow key={item.title} title={item.title} count={item.count} progress={item.progress} due={item.due} folder={item.folder} />
                ))}
              </div>
            )}
          </UiSection>

          <UiSection title="Typography / Spacing">
            <UiCard>
              <h2>長い日本語の教材名が入っても崩れないか確認します</h2>
              <p>RecaLoopでは市販教材名・章名・問題番号が長くなるため、余白と行間をここで調整します。</p>
            </UiCard>
          </UiSection>

          <UiSection title="Buttons">
            <div className={styles.buttonGrid}>
              <UiButton icon={<BookOpen size={18} />}>Primary</UiButton>
              <UiButton variant="secondary">Secondary</UiButton>
              <UiButton variant="tertiary">Tertiary</UiButton>
              <UiButton variant="destructive">Destructive</UiButton>
              <UiButton loading>Loading</UiButton>
              <UiButton disabled>Disabled</UiButton>
            </div>
            <div className={styles.iconRow}>
              <UiIconButton label="戻る" icon={<ChevronLeft size={20} />} />
              <UiIconButton label="検索" icon={<Search size={20} />} />
              <UiIconButton label="お知らせ" icon={<Bell size={20} />} selected />
              <UiIconButton label="その他" icon={<Ellipsis size={20} />} />
            </div>
          </UiSection>

          <UiSection title="Grouped List / Forms">
            <div className={styles.listGroup}>
              <UiListRow icon={<CalendarDays size={20} />} title="週のはじまり" value="月曜日" />
              <UiListRow icon={<Timer size={20} />} title="タイマー" subtitle="集中時間を測ります" value="25分" />
              <UiListRow icon={<Coffee size={20} />} title="Cafeテーマ" subtitle="通常UIカラーとは分離" value="準備中" />
              <div className={styles.formRow}>
                <label>Toggle</label>
                <UiToggle label={toggle ? "ON" : "OFF"} checked={toggle} onChange={setToggle} />
              </div>
            </div>
          </UiSection>

          <UiSection title="Modal / Bottom Sheet / Loading">
            <div className={styles.buttonGrid}>
              <UiButton variant="secondary" onClick={() => setSheetOpen(true)}>Bottom Sheet</UiButton>
              <UiButton variant="secondary">Action Sheet</UiButton>
              <UiButton variant="secondary">Alert</UiButton>
            </div>
            <UiBottomSheet title="教材を追加" open={sheetOpen} onClose={() => setSheetOpen(false)}>
              <UiButton size="full">新規デッキ作成</UiButton>
              <UiButton variant="secondary" size="full">.recaloop インポート</UiButton>
            </UiBottomSheet>
            <div className={styles.inlinePreview}>
              <UiEmptyState icon={<BookOpen size={28} />} title="教材がありません" body="追加ボタンから教材を作成できます。" />
              <div className={styles.loadingBox}>
                <UiLoadingOverlay label="UIラボのローディング確認" />
              </div>
            </div>
          </UiSection>

          <UiSection title="Study Screen Parts">
            <UiCard>
              <div className={styles.studyParts}>
                <small>Ⅰ / 第1章 数と式 / 1</small>
                <b>この図を見て答えなさい</b>
                <div className={styles.mediaPlaceholder}>画像・音声エリア</div>
                <UiButton variant="secondary" size="full">裏面を見る</UiButton>
                <RatingButtons />
              </div>
            </UiCard>
          </UiSection>

          <UiSection title="Calendar / Summary / Cafe Parts">
            <div className={styles.calendarGrid}>
              {Array.from({ length: 35 }, (_, index) => (
                <button key={index} className={index === 17 ? styles.today : ""}>
                  <span>{index + 1}</span>
                  <b>{index % 7 === 0 ? 12 : 0}</b>
                </button>
              ))}
            </div>
          </UiSection>

          <nav className={styles.tabBar}>
            {[
              [CalendarDays, "Home"],
              [RotateCcw, "Study"],
              [CalendarDays, "Calendar"],
              [Grid2X2, "Summary"],
              [Coffee, "Cafe"],
            ].map(([Icon, label], index) => {
              const IconComponent = Icon as typeof CalendarDays;
              return (
                <button key={label as string} className={index === 0 ? styles.active : ""}>
                  <IconComponent size={22} />
                  <span>{label as string}</span>
                </button>
              );
            })}
          </nav>
        </div>
      </div>
    </main>
  );
}
