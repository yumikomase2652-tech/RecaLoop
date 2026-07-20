# Cafeloop Cafe Asset Spec

This document defines the image assets needed to replace the current Phase 1 CSS placeholders. Do not copy assets from other apps. All assets should be original Cafeloop assets.

## Folder Structure

```text
public/cafe/
  themes/
    classic-coffee/
      background.png
      foreground.png
      thumbnail.png
    forest-window/
      background.png
      foreground.png
      thumbnail.png
  items/
    item-round-table.png
    item-reading-chair.png
    item-window-plant.png
    item-coffee-set.png
    item-sofa-bench.png
  visitors/
    visitor-mugi.png
    visitor-sumire.png
    visitor-kohaku.png
  gifts/
    gift-pressed-leaf.png
    gift-tiny-bean.png
```

## Scene Layers

The Cafe scene is rendered as React/CSS layers:

1. Background Layer: room wall, floor, static lighting.
2. Wall Decoration Layer: windows and wall decorations.
3. Back Furniture Layer: rugs or large back objects.
4. Visitor Layer: current visitors.
5. Front Furniture Layer: placed furniture, food, and drinks.
6. Effect Layer: optional small ambience effects.
7. Foreground Layer: front trim or overlay objects.

Use transparent PNG or WebP for all furniture, visitors, gifts, and foreground layers.

## Theme Assets

| Asset | Size | Aspect Ratio | Transparency | Notes |
| --- | ---: | ---: | --- | --- |
| background.png | 1600 x 1000 | 16:10 | No | Main room background. Safe for preview cropping. |
| foreground.png | 1600 x 1000 | 16:10 | Yes | Optional front layer such as table edge or plants. |
| thumbnail.png | 600 x 375 | 16:10 | No | Shop/Menu thumbnail. |

## Item Assets

| Placement Size | Recommended Image Size | Transparency | Origin / Anchor |
| --- | ---: | --- | --- |
| small | 360 x 360 | Yes | Bottom center |
| large | 640 x 420 | Yes | Bottom center |
| food | 320 x 220 | Yes | Bottom center |
| wall | 360 x 300 | Yes | Center |

Item file names should match `CafeItem.imageKey`, for example `item-round-table.png`.

## Visitor Assets

| Asset | Size | Transparency | Origin / Anchor |
| --- | ---: | --- | --- |
| visitor image | 360 x 420 | Yes | Bottom center |

Visitor file names should match `CafeVisitor.imageKey`, for example `visitor-mugi.png`.

## Slot Coordinates

Slots use percentages relative to the scene:

```ts
{
  id: "small_01",
  type: "small",
  xPercent: 12,
  yPercent: 56,
  widthPercent: 18,
  heightPercent: 18,
  zIndex: 6
}
```

The `xPercent` and `yPercent` values describe the top-left corner of the item box. The asset itself should be drawn with its visual base aligned near the bottom center of the transparent canvas.

## Phase 1 Placeholder Policy

Current Phase 1 implementation uses CSS shapes only:

- No extracted images.
- No copied characters.
- No copied UI assets.
- Data keys and layer structure are ready for asset replacement.

## Phase 2 DB Mapping

When DB-backed Cafe is implemented, these master keys should remain stable:

- `CafeTheme.sceneBackgroundKey`
- `CafeTheme.sceneForegroundKey`
- `CafeItem.imageKey`
- `CafeVisitor.imageKey`
- gift image key

Changing image files should not require changing user placement records.
