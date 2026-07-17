export type UiTokenKey =
  | "screenPaddingX"
  | "screenPaddingY"
  | "sectionGap"
  | "cardGap"
  | "gridGap"
  | "cardPadding"
  | "listRowPaddingY"
  | "listRowPaddingX"
  | "radiusSmall"
  | "radiusMedium"
  | "radiusLarge"
  | "radiusActionCard"
  | "radiusModal"
  | "radiusBottomSheet"
  | "buttonHeight"
  | "buttonCompactHeight"
  | "touchMin"
  | "actionCardHeight"
  | "materialGalleryCardWidth"
  | "materialCoverAspect"
  | "tabBarHeight"
  | "iconSmall"
  | "iconMedium"
  | "iconLarge"
  | "pageTitleSize"
  | "sectionTitleSize"
  | "bodySize"
  | "buttonLabelSize"
  | "captionSize"
  | "numericValueSize"
  | "lineHeight"
  | "fontWeightRegular"
  | "fontWeightMedium"
  | "fontWeightStrong"
  | "borderWidth"
  | "separatorOpacity"
  | "shadowBlur"
  | "shadowOpacity"
  | "backgroundContrast"
  | "pressedOpacity"
  | "disabledOpacity"
  | "backdropBlur"
  | "durationStandard"
  | "durationFast"
  | "durationSheet"
  | "pressScale"
  | "shopPreviewHeight";

export type UiColorKey = "textColor" | "accentColor" | "baseColor";

export type UiTokens = Record<UiTokenKey, number> & Record<UiColorKey, string> & {
  reduceMotion: boolean;
};

export type UiPresetName =
  | "RecaLoop Default"
  | "Compact"
  | "Comfortable"
  | "iOS-like"
  | "Route-English-like";

export type UiColorPresetName =
  | "Cafe"
  | "Simple White"
  | "Blue"
  | "Green"
  | "Pink"
  | "Monochrome";

export const defaultUiTokens: UiTokens = {
  screenPaddingX: 18,
  screenPaddingY: 14,
  sectionGap: 22,
  cardGap: 12,
  gridGap: 12,
  cardPadding: 16,
  listRowPaddingY: 13,
  listRowPaddingX: 16,
  radiusSmall: 10,
  radiusMedium: 16,
  radiusLarge: 24,
  radiusActionCard: 22,
  radiusModal: 24,
  radiusBottomSheet: 28,
  buttonHeight: 48,
  buttonCompactHeight: 38,
  touchMin: 44,
  actionCardHeight: 118,
  materialGalleryCardWidth: 96,
  materialCoverAspect: 1.42,
  tabBarHeight: 64,
  iconSmall: 16,
  iconMedium: 22,
  iconLarge: 30,
  pageTitleSize: 28,
  sectionTitleSize: 18,
  bodySize: 16,
  buttonLabelSize: 15,
  captionSize: 13,
  numericValueSize: 28,
  lineHeight: 1.42,
  fontWeightRegular: 450,
  fontWeightMedium: 650,
  fontWeightStrong: 800,
  borderWidth: 1,
  separatorOpacity: 0.16,
  shadowBlur: 18,
  shadowOpacity: 0.08,
  backgroundContrast: 0.96,
  pressedOpacity: 0.72,
  disabledOpacity: 0.42,
  backdropBlur: 18,
  durationStandard: 180,
  durationFast: 110,
  durationSheet: 260,
  pressScale: 0.98,
  shopPreviewHeight: 172,
  textColor: "#172f42",
  accentColor: "#f2a23a",
  baseColor: "#f7f3ec",
  reduceMotion: false,
};

export const uiPresets: Record<UiPresetName, UiTokens> = {
  "RecaLoop Default": defaultUiTokens,
  Compact: {
    ...defaultUiTokens,
    screenPaddingX: 14,
    sectionGap: 16,
    cardGap: 9,
    gridGap: 9,
    cardPadding: 13,
    radiusLarge: 19,
    radiusActionCard: 18,
    buttonHeight: 44,
    actionCardHeight: 102,
    pageTitleSize: 24,
    bodySize: 15,
    numericValueSize: 24,
    shopPreviewHeight: 138,
  },
  Comfortable: {
    ...defaultUiTokens,
    screenPaddingX: 22,
    screenPaddingY: 18,
    sectionGap: 28,
    cardGap: 15,
    gridGap: 15,
    cardPadding: 20,
    radiusLarge: 28,
    radiusActionCard: 26,
    buttonHeight: 52,
    actionCardHeight: 132,
    pageTitleSize: 30,
    bodySize: 17,
    numericValueSize: 32,
    shopPreviewHeight: 206,
  },
  "iOS-like": {
    ...defaultUiTokens,
    screenPaddingX: 20,
    screenPaddingY: 12,
    sectionGap: 24,
    cardGap: 10,
    gridGap: 12,
    cardPadding: 16,
    radiusMedium: 18,
    radiusLarge: 26,
    radiusActionCard: 24,
    buttonHeight: 50,
    actionCardHeight: 116,
    pageTitleSize: 28,
    bodySize: 17,
    lineHeight: 1.38,
    shadowBlur: 10,
    shadowOpacity: 0.04,
  },
  "Route-English-like": {
    ...defaultUiTokens,
    screenPaddingX: 18,
    sectionGap: 20,
    cardGap: 12,
    gridGap: 14,
    radiusMedium: 14,
    radiusLarge: 20,
    radiusActionCard: 18,
    buttonHeight: 48,
    actionCardHeight: 112,
    pageTitleSize: 26,
    bodySize: 16,
    shadowBlur: 14,
    shadowOpacity: 0.06,
    accentColor: "#2fc66d",
    baseColor: "#f4f4f7",
  },
};

export const uiColorPresets: Record<UiColorPresetName, Pick<UiTokens, UiColorKey>> = {
  Cafe: { textColor: "#172f42", accentColor: "#f2a23a", baseColor: "#f7f3ec" },
  "Simple White": { textColor: "#101418", accentColor: "#007aff", baseColor: "#f5f5f7" },
  Blue: { textColor: "#122c48", accentColor: "#2f80ed", baseColor: "#f2f7ff" },
  Green: { textColor: "#193a2a", accentColor: "#34c759", baseColor: "#f2f8ef" },
  Pink: { textColor: "#3d2531", accentColor: "#ff7aa8", baseColor: "#fff4f8" },
  Monochrome: { textColor: "#111111", accentColor: "#111111", baseColor: "#f4f4f4" },
};

export const tokenLabels: Record<UiTokenKey, string> = {
  screenPaddingX: "Screen padding X",
  screenPaddingY: "Screen padding Y",
  sectionGap: "Section gap",
  cardGap: "Card gap",
  gridGap: "Grid gap",
  cardPadding: "Card padding",
  listRowPaddingY: "List row padding Y",
  listRowPaddingX: "List row padding X",
  radiusSmall: "Small radius",
  radiusMedium: "Medium radius",
  radiusLarge: "Large radius",
  radiusActionCard: "Action card radius",
  radiusModal: "Modal radius",
  radiusBottomSheet: "Bottom sheet radius",
  buttonHeight: "Button height",
  buttonCompactHeight: "Compact button height",
  touchMin: "Minimum touch target",
  actionCardHeight: "Action card height",
  materialGalleryCardWidth: "Material gallery card width",
  materialCoverAspect: "Material cover aspect ratio",
  tabBarHeight: "Tab bar height",
  iconSmall: "Small icon",
  iconMedium: "Medium icon",
  iconLarge: "Large icon",
  pageTitleSize: "Page title size",
  sectionTitleSize: "Section title size",
  bodySize: "Body size",
  buttonLabelSize: "Button label size",
  captionSize: "Caption size",
  numericValueSize: "Numeric value size",
  lineHeight: "Line height",
  fontWeightRegular: "Regular weight",
  fontWeightMedium: "Medium weight",
  fontWeightStrong: "Strong weight",
  borderWidth: "Border width",
  separatorOpacity: "Separator opacity",
  shadowBlur: "Shadow blur",
  shadowOpacity: "Shadow opacity",
  backgroundContrast: "Background contrast",
  pressedOpacity: "Pressed opacity",
  disabledOpacity: "Disabled opacity",
  backdropBlur: "Backdrop blur",
  durationStandard: "Standard duration",
  durationFast: "Fast duration",
  durationSheet: "Sheet duration",
  pressScale: "Press scale",
  shopPreviewHeight: "Shop preview height",
};

export function tokensToCssVariables(tokens: UiTokens): Record<string, string> {
  return {
    "--lab-screen-padding-x": `${tokens.screenPaddingX}px`,
    "--lab-screen-padding-y": `${tokens.screenPaddingY}px`,
    "--lab-section-gap": `${tokens.sectionGap}px`,
    "--lab-card-gap": `${tokens.cardGap}px`,
    "--lab-grid-gap": `${tokens.gridGap}px`,
    "--lab-card-padding": `${tokens.cardPadding}px`,
    "--lab-list-row-padding-y": `${tokens.listRowPaddingY}px`,
    "--lab-list-row-padding-x": `${tokens.listRowPaddingX}px`,
    "--lab-radius-small": `${tokens.radiusSmall}px`,
    "--lab-radius-medium": `${tokens.radiusMedium}px`,
    "--lab-radius-large": `${tokens.radiusLarge}px`,
    "--lab-radius-action-card": `${tokens.radiusActionCard}px`,
    "--lab-radius-modal": `${tokens.radiusModal}px`,
    "--lab-radius-bottom-sheet": `${tokens.radiusBottomSheet}px`,
    "--lab-button-height": `${tokens.buttonHeight}px`,
    "--lab-button-compact-height": `${tokens.buttonCompactHeight}px`,
    "--lab-touch-min": `${tokens.touchMin}px`,
    "--lab-action-card-height": `${tokens.actionCardHeight}px`,
    "--lab-material-gallery-card-width": `${tokens.materialGalleryCardWidth}px`,
    "--lab-material-cover-aspect": `${tokens.materialCoverAspect}`,
    "--lab-tab-bar-height": `${tokens.tabBarHeight}px`,
    "--lab-icon-small": `${tokens.iconSmall}px`,
    "--lab-icon-medium": `${tokens.iconMedium}px`,
    "--lab-icon-large": `${tokens.iconLarge}px`,
    "--lab-page-title-size": `${tokens.pageTitleSize}px`,
    "--lab-section-title-size": `${tokens.sectionTitleSize}px`,
    "--lab-body-size": `${tokens.bodySize}px`,
    "--lab-button-label-size": `${tokens.buttonLabelSize}px`,
    "--lab-caption-size": `${tokens.captionSize}px`,
    "--lab-numeric-value-size": `${tokens.numericValueSize}px`,
    "--lab-line-height": `${tokens.lineHeight}`,
    "--lab-font-weight-regular": `${tokens.fontWeightRegular}`,
    "--lab-font-weight-medium": `${tokens.fontWeightMedium}`,
    "--lab-font-weight-strong": `${tokens.fontWeightStrong}`,
    "--lab-border-width": `${tokens.borderWidth}px`,
    "--lab-separator-opacity": `${tokens.separatorOpacity}`,
    "--lab-shadow-blur": `${tokens.shadowBlur}px`,
    "--lab-shadow-opacity": `${tokens.shadowOpacity}`,
    "--lab-background-contrast": `${tokens.backgroundContrast}`,
    "--lab-pressed-opacity": `${tokens.pressedOpacity}`,
    "--lab-disabled-opacity": `${tokens.disabledOpacity}`,
    "--lab-backdrop-blur": `${tokens.backdropBlur}px`,
    "--lab-duration-standard": tokens.reduceMotion ? "1ms" : `${tokens.durationStandard}ms`,
    "--lab-duration-fast": tokens.reduceMotion ? "1ms" : `${tokens.durationFast}ms`,
    "--lab-duration-sheet": tokens.reduceMotion ? "1ms" : `${tokens.durationSheet}ms`,
    "--lab-press-scale": tokens.reduceMotion ? "1" : `${tokens.pressScale}`,
    "--lab-shop-preview-height": `${tokens.shopPreviewHeight}px`,
    "--lab-text-color": tokens.textColor,
    "--lab-accent-color": tokens.accentColor,
    "--lab-base-color": tokens.baseColor,
  };
}

export function tokensToCssText(tokens: UiTokens) {
  return `:root {\n${Object.entries(tokensToCssVariables(tokens))
    .map(([key, value]) => `  ${key}: ${value};`)
    .join("\n")}\n}`;
}

