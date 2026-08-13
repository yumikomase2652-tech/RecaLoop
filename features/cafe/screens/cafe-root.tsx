"use client";

import { useMemo, useState } from "react";
import type { ElementType, ReactNode } from "react";
import { Camera, ChevronLeft, ChevronRight, Gift, Images, PackageOpen, Paintbrush, Plus, RotateCcw, ShoppingBag, Sparkles, Store, Users } from "lucide-react";
import { CafeScene } from "../components/cafe-scene";
import styles from "../components/cafe.module.css";
import { cafeGifts } from "../data/mock-gifts";
import { cafeItems } from "../data/mock-items";
import { cafeSlotLayouts } from "../data/mock-slots";
import { cafeExpansions, cafeThemes } from "../data/mock-themes";
import { cafeVisitors } from "../data/mock-visitors";
import { useCafeState } from "../hooks/use-cafe-state";
import type { CafePlacement, CafeScreen, CafeSlot } from "../types/cafe";

type CafeRootProps = {
  compact?: boolean;
};

const menuButtons: { id: CafeScreen; label: string; icon: ElementType }[] = [
  { id: "goods", label: "Goods", icon: PackageOpen },
  { id: "shop", label: "Shop", icon: ShoppingBag },
  { id: "visitors", label: "Visitors", icon: Users },
  { id: "album", label: "Album", icon: Images },
  { id: "gifts", label: "Gifts", icon: Gift },
  { id: "menu", label: "Menu", icon: Store },
];

export function CafeRoot({ compact = false }: CafeRootProps) {
  const [screen, setScreen] = useState<CafeScreen>("home");
  const cafe = useCafeState();

  if (compact) {
    return (
      <CafeScene
        mode="preview"
        theme={cafe.activeTheme}
        slotLayoutId={cafe.activeExpansion.slotLayoutId}
        placements={cafe.state.placements}
        visits={cafe.currentVisits}
      />
    );
  }

  return (
    <div className={styles.root}>
      {screen === "home" && <CafeHomeScreen cafe={cafe} setScreen={setScreen} />}
      {screen === "goods" && <GoodsScreen cafe={cafe} back={() => setScreen("home")} />}
      {screen === "shop" && <ShopScreen cafe={cafe} back={() => setScreen("home")} />}
      {screen === "visitors" && <VisitorsScreen cafe={cafe} back={() => setScreen("home")} />}
      {screen === "album" && <AlbumScreen cafe={cafe} back={() => setScreen("home")} />}
      {screen === "gifts" && <GiftsScreen cafe={cafe} back={() => setScreen("home")} />}
      {screen === "menu" && <MenuScreen cafe={cafe} setScreen={setScreen} />}
    </div>
  );
}

type CafeHook = ReturnType<typeof useCafeState>;

function CafeHomeScreen({ cafe, setScreen }: { cafe: CafeHook; setScreen: (screen: CafeScreen) => void }) {
  const active = cafe.currentVisits.length;
  const claimable = cafe.claimableVisits.length;
  const latestClaim = cafe.claimableVisits[0];

  return (
    <div className={styles.screenShell}>
      <div className={styles.topBar}>
        <div>
          <h1>Cafe</h1>
          <p>{cafe.activeExpansion.name} ・ {cafe.activeTheme.name}</p>
        </div>
        <span className={styles.coinPill}>coin {cafe.state.coins}</span>
      </div>
      <CafeScene
        mode="full"
        theme={cafe.activeTheme}
        slotLayoutId={cafe.activeExpansion.slotLayoutId}
        placements={cafe.state.placements}
        visits={cafe.currentVisits}
      />
      <div className={styles.quickStrip}>
        <button type="button" onClick={() => setScreen("goods")}><PackageOpen size={18} /> グッズ</button>
        <button type="button" onClick={() => setScreen("shop")}><ShoppingBag size={18} /> お店</button>
        <button type="button" onClick={() => setScreen("visitors")}><Users size={18} /> お客さん</button>
        <button type="button" onClick={() => setScreen("album")}><Camera size={18} /> 写真</button>
      </div>
      <section className={styles.card}>
        <div className={styles.summaryGrid}>
          <span className={styles.summaryTile}><span>来店中</span><b>{active}</b></span>
          <span className={styles.summaryTile}><span>受取待ち</span><b>{claimable}</b></span>
          <span className={styles.summaryTile}><span>設置中</span><b>{cafe.state.placements.length}</b></span>
        </div>
        {latestClaim && (
          <p className={styles.rewardNotice}>
            {cafeVisitors.find((visitor) => visitor.id === latestClaim.visitorId)?.name || "お客さん"}が {latestClaim.rewardCoins} coin を残しています。
          </p>
        )}
        <div className={styles.buttonRow} style={{ marginTop: 14 }}>
          <button className={styles.primaryButton} type="button" disabled={!claimable} onClick={() => cafe.claimRewards()}>
            コインをまとめて受け取る
          </button>
          <button className={styles.secondaryButton} type="button" onClick={() => cafe.switchExpansion(cafe.state.activeExpansionId === "tiny-room" ? "wide-room" : "tiny-room")}>
            初期/拡張を確認
          </button>
        </div>
      </section>
      <div className={styles.navGrid}>
        {menuButtons.map(({ id, label, icon: Icon }) => (
          <button className={styles.navButton} key={id} type="button" onClick={() => setScreen(id)}>
            <Icon size={22} />
            {label}
          </button>
        ))}
      </div>
    </div>
  );
}

function ScreenHeader({ title, subtitle, action, back }: { title: string; subtitle?: string; action?: ReactNode; back: () => void }) {
  return (
    <div className={styles.subBar}>
      <button className={styles.backButton} type="button" onClick={back} aria-label="Cafeへ戻る"><ChevronLeft size={22} /></button>
      <div>
        <h2>{title}</h2>
        {subtitle && <p>{subtitle}</p>}
      </div>
      <span>{action}</span>
    </div>
  );
}

function GoodsScreen({ cafe, back }: { cafe: CafeHook; back: () => void }) {
  const [draft, setDraft] = useState<CafePlacement[]>(cafe.state.placements);
  const [selectedSlot, setSelectedSlot] = useState<CafeSlot | null>(null);
  const owned = cafe.ownedItems;
  const selectedPlacement = selectedSlot ? draft.find((placement) => placement.slotId === selectedSlot.id) : null;
  const available = selectedSlot ? owned.filter((item) => item.placementSize === selectedSlot.type) : owned;

  const place = (itemId: string) => {
    if (!selectedSlot) return;
    setDraft((current) => [...current.filter((placement) => placement.slotId !== selectedSlot.id), { slotId: selectedSlot.id, itemId }]);
  };

  const clear = () => {
    if (!selectedSlot) return;
    setDraft((current) => current.filter((placement) => placement.slotId !== selectedSlot.id));
  };

  return (
    <div className={styles.screenShell}>
      <ScreenHeader title="Goods" subtitle="スロットを選んで配置します。" back={back} action={<button className={styles.primaryButton} type="button" onClick={() => cafe.savePlacements(draft)}>保存</button>} />
      <CafeScene
        mode="editor"
        theme={cafe.activeTheme}
        slotLayoutId={cafe.activeExpansion.slotLayoutId}
        placements={draft}
        visits={cafe.currentVisits}
        selectedSlotId={selectedSlot?.id || null}
        onSelectSlot={setSelectedSlot}
      />
      <section className={styles.card}>
        <div className={styles.itemTop}>
          <div>
            <b>{selectedSlot ? `${selectedSlot.id} に置く` : "設置場所を選択"}</b>
            <p>{selectedPlacement ? "現在: " + cafeItems.find((item) => item.id === selectedPlacement.itemId)?.name : "空きスロットです"}</p>
          </div>
          <button className={styles.secondaryButton} type="button" disabled={!selectedSlot || !selectedPlacement} onClick={clear}>片付ける</button>
        </div>
      </section>
      <div className={styles.itemGrid}>
        {available.map((item) => (
          <button className={styles.itemCard} key={item.id} type="button" onClick={() => place(item.id)} disabled={!selectedSlot}>
            <span className={styles.itemTop}>
              <b>{item.name}</b>
              <span className={styles.price}>{item.placementSize}</span>
            </span>
            <p>{item.description}</p>
          </button>
        ))}
      </div>
      {!selectedSlot && <p className={styles.empty}>Scene上の点線スロットを選ぶと、置ける所持品だけ表示されます。</p>}
    </div>
  );
}

function ShopScreen({ cafe, back }: { cafe: CafeHook; back: () => void }) {
  const [message, setMessage] = useState("");
  const [shopTab, setShopTab] = useState<"items" | "themes" | "expansion">("items");
  const buy = (label: string, run: () => string) => {
    if (typeof window !== "undefined" && !window.confirm(`${label}を購入/切り替えしますか？`)) return;
    const error = run();
    setMessage(error || `${label}を反映しました`);
  };

  return (
    <div className={styles.screenShell}>
      <ScreenHeader title="Shop" subtitle="家具・テーマ・拡張を増やします。" back={back} action={<span className={styles.coinPill}>coin {cafe.state.coins}</span>} />
      {message && <p className={styles.empty}>{message}</p>}
      <div className={styles.tabs} role="tablist" aria-label="Shop category">
        <button className={styles.tab} data-active={shopTab === "items"} type="button" onClick={() => setShopTab("items")}>家具・メニュー</button>
        <button className={styles.tab} data-active={shopTab === "themes"} type="button" onClick={() => setShopTab("themes")}>テーマ</button>
        <button className={styles.tab} data-active={shopTab === "expansion"} type="button" onClick={() => setShopTab("expansion")}>拡張</button>
      </div>
      {shopTab === "items" && <section className={styles.card}>
        <h2 style={{ margin: 0, fontSize: 17 }}>家具・メニュー</h2>
        <div className={styles.itemGrid} style={{ marginTop: 12 }}>
          {cafeItems.map((item) => {
            const owned = cafe.state.ownedItemIds.includes(item.id);
            return (
              <article className={styles.itemCard} key={item.id}>
                <span className={styles.itemTop}>
                  <b>{item.name}</b>
                  <span className={styles.price}>{owned ? "購入済み" : `${item.price} coin`}</span>
                </span>
                <p>{item.description}</p>
                <button className={owned ? styles.secondaryButton : styles.primaryButton} type="button" disabled={owned} onClick={() => buy(item.name, () => cafe.buyItem(item.id))}>
                  {owned ? "持っています" : "購入"}
                </button>
              </article>
            );
          })}
        </div>
      </section>}
      {shopTab === "themes" && <section className={styles.card}>
        <h2 style={{ margin: 0, fontSize: 17 }}>Cafeテーマ</h2>
        <div className={styles.itemGrid} style={{ marginTop: 12 }}>
          {cafeThemes.map((theme) => (
            <article className={styles.itemCard} key={theme.id}>
              <span className={styles.itemTop}>
                <b>{theme.name}</b>
                <span className={styles.price}>{cafe.state.ownedThemeIds.includes(theme.id) ? "所持" : `${theme.price} coin`}</span>
              </span>
              <p>{theme.description}</p>
              <button className={styles.secondaryButton} type="button" onClick={() => buy(theme.name, () => cafe.buyTheme(theme.id))}>
                {cafe.state.activeThemeId === theme.id ? "使用中" : cafe.state.ownedThemeIds.includes(theme.id) ? "切り替え" : "購入"}
              </button>
            </article>
          ))}
        </div>
      </section>}
      {shopTab === "expansion" && <section className={styles.card}>
        <h2 style={{ margin: 0, fontSize: 17 }}>Cafe拡張</h2>
        <div className={styles.itemGrid} style={{ marginTop: 12 }}>
          {cafeExpansions.map((expansion) => (
            <article className={styles.itemCard} key={expansion.id}>
              <span className={styles.itemTop}>
                <b>{expansion.name}</b>
                <span className={styles.price}>{cafe.state.ownedExpansionIds.includes(expansion.id) ? "所持" : `${expansion.price} coin`}</span>
              </span>
              <p>スロット {cafeSlotLayouts[expansion.slotLayoutId]?.length || 0} ・ 同時来店 {expansion.maxVisitors}</p>
              <button className={styles.secondaryButton} type="button" onClick={() => buy(expansion.name, () => cafe.buyExpansion(expansion.id))}>
                {cafe.state.activeExpansionId === expansion.id ? "使用中" : cafe.state.ownedExpansionIds.includes(expansion.id) ? "切り替え" : "購入"}
              </button>
            </article>
          ))}
        </div>
      </section>}
    </div>
  );
}

function VisitorsScreen({ cafe, back }: { cafe: CafeHook; back: () => void }) {
  const seen = new Set(cafe.state.visits.map((visit) => visit.visitorId));
  const visitCounts = new Map<string, number>();
  cafe.state.visits.forEach((visit) => visitCounts.set(visit.visitorId, (visitCounts.get(visit.visitorId) || 0) + 1));
  return (
    <div className={styles.screenShell}>
      <ScreenHeader title="Visitors" subtitle="来店中・履歴・図鑑です。" back={back} action={<button className={styles.primaryButton} type="button" disabled={!cafe.claimableVisits.length} onClick={() => cafe.claimRewards()}>一括受取</button>} />
      <section className={styles.card}>
        <h2 style={{ margin: 0, fontSize: 17 }}>現在来店中</h2>
        {cafe.currentVisits.length ? cafe.currentVisits.map((visit) => <VisitRow key={visit.id} visit={visit} />) : <p className={styles.empty}>今は静かなCafeです。</p>}
      </section>
      <section className={styles.card}>
        <h2 style={{ margin: 0, fontSize: 17 }}>最近来たお客さん</h2>
        {cafe.state.visits.slice(0, 8).map((visit) => <VisitRow key={visit.id} visit={visit} rewardAction={!visit.rewardClaimedAt && new Date(visit.endedAt).getTime() <= Date.now() ? () => cafe.claimRewards([visit.id]) : undefined} />)}
      </section>
      <section className={styles.card}>
        <h2 style={{ margin: 0, fontSize: 17 }}>お客さん図鑑</h2>
        {cafeVisitors.map((visitor) => (
          <div className={styles.visitRow} key={visitor.id}>
            <span className={styles.avatarDot}>{seen.has(visitor.id) ? visitor.name.slice(0, 1) : "?"}</span>
            <span>
              <b>{seen.has(visitor.id) ? visitor.name : "未来のお客さん"}</b>
              <p className={styles.visitMeta}>{seen.has(visitor.id) ? `${visitor.description} ・ 来店 ${visitCounts.get(visitor.id) || 0}回` : "Cafeに来ると記録されます。"}</p>
            </span>
          </div>
        ))}
      </section>
    </div>
  );
}

function VisitRow({ visit, rewardAction }: { visit: { visitorId: string; usedItemId?: string; endedAt: string; rewardCoins: number; rewardClaimedAt?: string }; rewardAction?: () => void }) {
  const visitor = cafeVisitors.find((candidate) => candidate.id === visit.visitorId);
  const item = cafeItems.find((candidate) => candidate.id === visit.usedItemId);
  const ended = new Date(visit.endedAt).getTime() <= Date.now();
  return (
    <div className={styles.visitRow}>
      <span className={styles.avatarDot}>{visitor?.name.slice(0, 1) || "?"}</span>
      <span>
        <b>{visitor?.name || "お客さん"}</b>
        <p className={styles.visitMeta}>{ended ? "退店済み" : "来店中"} ・ {item?.name || "店内"} ・ {visit.rewardCoins} coin</p>
      </span>
      {rewardAction && <button className={styles.secondaryButton} type="button" onClick={rewardAction}>受取</button>}
    </div>
  );
}

function AlbumScreen({ cafe, back }: { cafe: CafeHook; back: () => void }) {
  return (
    <div className={styles.screenShell}>
      <ScreenHeader title="Album" subtitle="Cafeの思い出を保存していく場所です。" back={back} />
      <CafeScene mode="preview" theme={cafe.activeTheme} slotLayoutId={cafe.activeExpansion.slotLayoutId} placements={cafe.state.placements} visits={cafe.currentVisits} />
      <div className={styles.itemGrid}>
        {cafe.state.albumPhotos.map((photo) => (
          <article className={styles.itemCard} key={photo.id}>
            <span className={styles.itemTop}>
              <b>{photo.title}</b>
              <span className={styles.price}>{new Date(photo.createdAt).toLocaleDateString("ja-JP")}</span>
            </span>
            <p>{photo.visitorIds.length}人の来店記録 ・ {cafeThemes.find((theme) => theme.id === photo.themeId)?.name}</p>
          </article>
        ))}
      </div>
    </div>
  );
}

function GiftsScreen({ cafe, back }: { cafe: CafeHook; back: () => void }) {
  return (
    <div className={styles.screenShell}>
      <ScreenHeader title="Gifts" subtitle="お客さんからの思い出の品です。" back={back} />
      <div className={styles.itemGrid}>
        {cafeGifts.map((gift) => {
          const owned = cafe.state.gifts.includes(gift.id);
          const visitor = gift.fromVisitorId ? cafeVisitors.find((item) => item.id === gift.fromVisitorId) : null;
          return (
            <article className={styles.itemCard} key={gift.id}>
              <span className={styles.itemTop}>
                <b>{owned ? gift.name : "未受取のプレゼント"}</b>
                <span className={styles.price}>{owned ? "受取済み" : "未発見"}</span>
              </span>
              <p>{owned ? gift.description : `${visitor?.name || "お客さん"}が置いていくことがあります。`}</p>
            </article>
          );
        })}
      </div>
    </div>
  );
}

function MenuScreen({ cafe, setScreen }: { cafe: CafeHook; setScreen: (screen: CafeScreen) => void }) {
  const inventoryCount = cafe.state.ownedItemIds.length + cafe.state.ownedThemeIds.length + cafe.state.ownedExpansionIds.length;
  const rows = useMemo(() => [
    { label: "Cafe Theme", value: cafe.activeTheme.name, action: () => setScreen("shop"), icon: Paintbrush },
    { label: "Expansion", value: cafe.activeExpansion.name, action: () => setScreen("shop"), icon: Plus },
    { label: "Inventory", value: `${inventoryCount}件`, action: () => setScreen("goods"), icon: PackageOpen },
    { label: "Settings", value: "Phase 2で同期予定", action: () => undefined, icon: Sparkles },
  ], [cafe.activeExpansion.name, cafe.activeTheme.name, inventoryCount, setScreen]);

  return (
    <div className={styles.screenShell}>
      <ScreenHeader title="Menu" subtitle="Cafeの管理メニューです。" back={() => setScreen("home")} />
      <section className={styles.card}>
        {rows.map(({ label, value, action, icon: Icon }) => (
          <button className={styles.visitRow} key={label} type="button" onClick={action}>
            <span className={styles.avatarDot}><Icon size={20} /></span>
            <span>
              <b>{label}</b>
              <p className={styles.visitMeta}>{value}</p>
            </span>
            <ChevronRight size={18} />
          </button>
        ))}
        <button className={styles.visitRow} type="button" onClick={() => cafe.resetCafe()}>
          <span className={styles.avatarDot}><RotateCcw size={20} /></span>
          <span>
            <b>リセット</b>
            <p className={styles.visitMeta}>Phase 1のCafe状態を初期化</p>
          </span>
          <ChevronRight size={18} />
        </button>
      </section>
    </div>
  );
}
