# uebersicht-claude-tokens brand

The mark is called **Counting Bars**. Four rising bars, the last one hollow: what has been used today, and what remains. A desktop widget is glanced at from across the room, and bars survive that; arcs and rings do not.

This is a widget, so the asset set is deliberately minimal: the symbol and the README banners. It inherits the account palette and shares turquoise with switchdeck by design; the symbol, not the colour, carries identity.

---

## Construction

The symbol is drawn on a **96 unit grid**. Bars are 12 wide, radius 6, on a shared baseline at y 78, with 6 unit gaps.

| Element | Geometry |
|---|---|
| Filled bars | x 15, 33, 51; tops y 58, 46, 34 |
| Hollow bar | x 69, top y 22, stroke 6 |
| Optical centre | 48, 50 |

The three filled bars are accent; the hollow bar takes the text colour, so "remaining" reads as ground, not as more usage.

---

## Colour

| Context | Ground | Filled bars | Hollow bar |
|---|---|---|---|
| Light | `bg` `#F7F5F2` | `accent` `#0F7D74` | `text` `#1C1B1D` |
| Dark | `bg` `#1C1B1D` | `accent` `#2FD4C4` | `text` `#F7F5F2` |

---

## Minimum sizes

| Asset | Minimum |
|---|---|
| Symbol, colour | 16 px |
| Symbol, monochrome | 18 px |

---

## Files

```
design/
  logo/     symbol light, dark, mono black, mono white; wordmark
  github/   readme banners 1400x400, screenshot.png
```

Filenames carry pixel dimensions for raster deliverables.

---

## Do not

1. Do not fill the fourth bar; hollow is the point.
2. Do not recolour outside the tokens above.
3. Do not add shadows, gradients, glows, or strokes.
4. Do not turn the bars into a live usage gauge; the mark is fixed geometry.

*Mark designed 2026-07-28. Built by Claude (Anthropic), directed by Shashank Karpal.*
