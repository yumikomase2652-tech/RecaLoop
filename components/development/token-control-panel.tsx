"use client";

import type { UiColorPresetName, UiPresetName, UiTokenKey, UiTokens } from "@/lib/ui-tokens";
import { defaultUiTokens, tokenLabels, tokensToCssText, uiColorPresets, uiPresets } from "@/lib/ui-tokens";

type TokenControlPanelProps = {
  tokens: UiTokens;
  setTokens: (tokens: UiTokens) => void;
  copied: string;
  setCopied: (message: string) => void;
};

const groups: { title: string; keys: UiTokenKey[] }[] = [
  { title: "Layout", keys: ["screenPaddingX", "screenPaddingY", "sectionGap", "cardGap", "gridGap", "cardPadding", "listRowPaddingY", "listRowPaddingX"] },
  { title: "Radius", keys: ["radiusSmall", "radiusMedium", "radiusLarge", "radiusActionCard", "radiusModal", "radiusBottomSheet"] },
  { title: "Size", keys: ["buttonHeight", "buttonCompactHeight", "touchMin", "actionCardHeight", "materialGalleryCardWidth", "materialCoverAspect", "tabBarHeight", "iconSmall", "iconMedium", "iconLarge"] },
  { title: "Typography", keys: ["pageTitleSize", "sectionTitleSize", "bodySize", "buttonLabelSize", "captionSize", "numericValueSize", "lineHeight", "fontWeightRegular", "fontWeightMedium", "fontWeightStrong"] },
  { title: "Appearance", keys: ["borderWidth", "separatorOpacity", "shadowBlur", "shadowOpacity", "backgroundContrast", "pressedOpacity", "disabledOpacity", "backdropBlur"] },
  { title: "Motion", keys: ["durationStandard", "durationFast", "durationSheet", "pressScale", "shopPreviewHeight"] },
];

const tokenRanges: Partial<Record<UiTokenKey, [number, number, number]>> = {
  materialCoverAspect: [1, 1.8, 0.01],
  lineHeight: [1.1, 1.8, 0.01],
  separatorOpacity: [0, 0.5, 0.01],
  shadowOpacity: [0, 0.25, 0.01],
  backgroundContrast: [0.82, 1, 0.01],
  pressedOpacity: [0.45, 1, 0.01],
  disabledOpacity: [0.2, 0.75, 0.01],
  pressScale: [0.92, 1, 0.005],
  fontWeightRegular: [350, 600, 10],
  fontWeightMedium: [500, 760, 10],
  fontWeightStrong: [700, 950, 10],
};

function rangeFor(key: UiTokenKey): [number, number, number] {
  if (tokenRanges[key]) return tokenRanges[key]!;
  if (key.includes("duration")) return [0, 600, 10];
  if (key.includes("Opacity")) return [0, 1, 0.01];
  if (key.includes("radius") || key.includes("Radius")) return [0, 40, 1];
  if (key.includes("Padding") || key.includes("Gap")) return [0, 40, 1];
  if (key.includes("Size") || key.includes("Height") || key.includes("Width")) return [8, 260, 1];
  if (key.includes("icon") || key.includes("Icon")) return [10, 44, 1];
  if (key.includes("Weight")) return [300, 950, 10];
  return [0, 100, 1];
}

async function copyText(value: string, setCopied: (message: string) => void) {
  try {
    await navigator.clipboard.writeText(value);
    setCopied("コピーしました");
  } catch {
    setCopied("コピーできませんでした。下のJSONを手動でコピーしてください。");
  }
}

export function TokenControlPanel({ tokens, setTokens, copied, setCopied }: TokenControlPanelProps) {
  const update = (key: UiTokenKey, value: number) => setTokens({ ...tokens, [key]: value });
  const applyPreset = (name: UiPresetName) => setTokens(uiPresets[name]);
  const applyColor = (name: UiColorPresetName) => setTokens({ ...tokens, ...uiColorPresets[name] });
  const loadJson = (value: string) => {
    try {
      const next = JSON.parse(value) as UiTokens;
      setTokens({ ...defaultUiTokens, ...next });
      setCopied("JSONを読み込みました");
    } catch {
      setCopied("JSONを読み込めませんでした");
    }
  };

  return (
    <aside className="lab-token-panel">
      <div className="lab-token-sticky">
        <h2>Token Controls</h2>
        <p>UIラボ内だけに即時反映されます。本番画面の値は変更しません。</p>

        <label>
          Preset
          <select onChange={(event) => applyPreset(event.target.value as UiPresetName)} defaultValue="RecaLoop Default">
            {(Object.keys(uiPresets) as UiPresetName[]).map((name) => <option key={name}>{name}</option>)}
          </select>
        </label>

        <label>
          Color preset
          <select onChange={(event) => applyColor(event.target.value as UiColorPresetName)} defaultValue="Cafe">
            {(Object.keys(uiColorPresets) as UiColorPresetName[]).map((name) => <option key={name}>{name}</option>)}
          </select>
        </label>

        <div className="lab-color-controls">
          <label>Text<input type="color" value={tokens.textColor} onChange={(event) => setTokens({ ...tokens, textColor: event.target.value })} /></label>
          <label>Accent<input type="color" value={tokens.accentColor} onChange={(event) => setTokens({ ...tokens, accentColor: event.target.value })} /></label>
          <label>Base<input type="color" value={tokens.baseColor} onChange={(event) => setTokens({ ...tokens, baseColor: event.target.value })} /></label>
        </div>

        <button onClick={() => setTokens(defaultUiTokens)}>初期値に戻す</button>
        <button onClick={() => copyText(JSON.stringify(tokens, null, 2), setCopied)}>現在値をコピー</button>
        <button onClick={() => copyText(tokensToCssText(tokens), setCopied)}>CSS変数をコピー</button>
        <label className="lab-reduce-motion">
          <input type="checkbox" checked={tokens.reduceMotion} onChange={(event) => setTokens({ ...tokens, reduceMotion: event.target.checked })} />
          Reduce Motion preview
        </label>
        {copied && <small>{copied}</small>}
      </div>

      {groups.map((group) => (
        <section key={group.title} className="lab-token-group">
          <h3>{group.title}</h3>
          {group.keys.map((key) => {
            const [min, max, step] = rangeFor(key);
            return (
              <label key={key} className="lab-token-row">
                <span>{tokenLabels[key]}</span>
                <input type="range" min={min} max={max} step={step} value={tokens[key]} onChange={(event) => update(key, Number(event.target.value))} />
                <input type="number" min={min} max={max} step={step} value={tokens[key]} onChange={(event) => update(key, Number(event.target.value))} />
              </label>
            );
          })}
        </section>
      ))}

      <section className="lab-token-group">
        <h3>JSON import / export</h3>
        <textarea value={JSON.stringify(tokens, null, 2)} onChange={(event) => loadJson(event.target.value)} spellCheck={false} />
        <ol>
          <li>UIラボで値を調整</li>
          <li>「CSS変数をコピー」を押す</li>
          <li>`lib/ui-tokens.ts` または正式CSSへ反映</li>
          <li>本番画面を確認</li>
        </ol>
      </section>
    </aside>
  );
}

