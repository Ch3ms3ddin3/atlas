# Atlas — Brand Guidelines

**Direction:** Architectural — *The Threshold*  
**Version:** 1.0  
**Status:** Locked (Phase 1)

---

## Brand essence

Atlas is a trusted everyday companion for residents, MRE, expats, and visitors in Morocco. The identity expresses **structure and calm** — the moment you cross from uncertainty into clarity, like entering a well-run riad.

| Principle | Expression |
|---|---|
| Minimal | Doorway geometry only — pillars, arch, void |
| Timeless | Grid-built marks, material colors |
| Premium | Whitespace, border-defined surfaces, scarce accent |
| Calm | Information leads; chrome recedes |
| Moroccan | Through plaster, clay, cedar shadow — never motif or cliché |

**Design test:** Would this belong on the nameplate of a serious riad — not a tour desk or ministry lobby?

**Never use:** zellige patterns, camels, mosques as hero, gold gradients, souk photography, ornate lanterns, compass roses, map pins as logo.

---

## Logo — The Threshold

### Concept

Two pillars and a soft arch form a doorway. Negative space reads as an abstract `A`. A single terracotta dot marks the apex — the only warm accent in the mark.

### Construction grid (100 × 100 units)

| Element | Specification |
|---|---|
| Left pillar | `x=32`, `y=28→72`, stroke `4`, `#1A2332`, round caps |
| Right pillar | `x=64`, `y=28→72`, stroke `4`, `#1A2332`, round caps |
| Arch | Quadratic bezier `(36,28) → (50,16) → (64,28)`, stroke `4`, `#1A2332` |
| Apex dot | Center `(50,14)`, diameter `4`, `#C4654A` |
| Negative space | Forms `A` silhouette — never filled |

### Wordmark

| Property | Value |
|---|---|
| Text | `ATLAS` |
| Typeface | Inter SemiBold (600) — Söhne Halbfett when licensed |
| Letter-spacing | `+0.12em` (+120 tracking) |
| Color | `#1A2332` |
| Case | All caps |

### Lockups

| Variant | File | Use |
|---|---|---|
| Horizontal | `brand/logos/atlas-logo-horizontal.svg` | App bar, marketing, email |
| Stacked | `brand/logos/atlas-logo-stacked.svg` | Splash, onboarding, posters |
| Reversed | `brand/logos/atlas-logo-reversed.svg` | Dark surfaces, photography overlays |
| Mark only | `brand/logos/atlas-mark.svg` | Watermark, loading, ≥32px |
| Mark compact | `brand/logos/atlas-mark-no-dot.svg` | Favicon, ≤32px |

### Clear space

Minimum clear space on all sides = height of the letter `A` in the wordmark (or mark height when mark-only).

### Minimum sizes

| Context | Minimum |
|---|---|
| Horizontal lockup | 120px wide |
| Stacked lockup | 80px wide |
| Mark only | 24px (favicon); no apex dot below 32px |

### Logo misuse

Do not stretch, rotate, add shadows, outline, recolor strokes, place on busy photography, or add patterns inside the void.

---

## App icon

| Property | Value |
|---|---|
| File | `brand/icons/atlas-app-icon-1024.png` |
| Canvas | 1024 × 1024 px |
| Background | `#FAF7F2` solid |
| Mark | Threshold monogram, centered in 80% safe zone |
| Pillars + arch | `#1A2332` |
| Apex dot | `#C4654A` |
| Gradients / shadows | None |

### Android adaptive (export)

| File | Role |
|---|---|
| `brand/android-adaptive/ic_launcher_background.xml` | Solid `#FAF7F2` |
| `brand/android-adaptive/ic_launcher_foreground.xml` | Threshold vector |
| `brand/android-adaptive/ic_launcher.xml` | Adaptive wrapper |

---

## Splash screen (spec — Phase 3)

| Element | Value |
|---|---|
| Background | `#FAF7F2` |
| Mark | Threshold, ~48pt, centered |
| Wordmark | `ATLAS`, 18pt, SemiBold, `+0.12em` |
| Horizon rule | 1px `#D9CDB8` at 60% opacity, inset 48px, `y ≈ 78%` |

### Animation (≤ 1200ms)

1. Arch draws (0–500ms, ease-in-out)
2. Pillars fade (200–500ms)
3. Apex dot scales in (400–600ms)
4. Wordmark fades + rises 8px (500–900ms)
5. Horizon fades (700–1000ms)
6. Crossfade to Home (900–1200ms)

`reduce motion`: static mark + opacity fade only.

---

## Color palette

### Core

| Token | HEX | Role |
|---|---|---|
| `warmOffWhite` | `#FAF7F2` | Scaffold, icon/splash background |
| `surfaceWhite` | `#FFFFFF` | Elevated cards |
| `midnightBlue` | `#1A2332` | Primary text, logo strokes |
| `terracotta` | `#C4654A` | Apex dot, CTAs, active navigation |
| `sand` | `#D9CDB8` | Primary card borders |
| `subtleGold` | `#C4A35A` | Rare premium hints only |

### Structural

| Token | HEX | Role |
|---|---|---|
| `sandMuted` | `#E8E0D4` | Standard borders, dividers |
| `terracottaMuted` | `#E8B5A5` | Selected chips |
| `midnightBlueMuted` | `#5A6472` | Secondary text, inactive icons |
| `midnightBlueFaint` | `#8A939F` | Placeholders, disabled |
| `terracottaDeep` | `#A8503A` | Button pressed state |
| `terracottaGhost` | `#F5E8E4` | Soft tinted surfaces |

### Functional

| Token | HEX | Role |
|---|---|---|
| `success` | `#3D6B5E` | Confirmations |
| `successMuted` | `#E8F0ED` | Success containers |
| `warning` | `#9A7B2F` | Caution |
| `warningMuted` | `#F5F0E4` | Warning containers |
| `error` | `#B3261E` | Errors |
| `errorMuted` | `#F9DEDC` | Error containers |
| `info` | `#4A6FA5` | Informational |
| `infoMuted` | `#E8EEF5` | Info containers |

### Usage rules

- Distribution: ~60% warm surfaces, ~30% text, ~8% structure, ~2% terracotta accent
- Maximum **2 terracotta elements** visible per screen
- No gold gradients, category rainbow coding, or `#000000` text

---

## Typography

| Token | Size | Line height | Weight | Letter-spacing | Use |
|---|---|---|---|---|---|
| `displayMedium` | 32px | 36px | 300 | −1.2px | Home greeting |
| `headlineLarge` | 24px | 30px | 600 | −0.3px | Page titles |
| `headlineMedium` | 20px | 26px | 600 | −0.2px | Modal titles |
| `titleLarge` | 18px | 24px | 600 | 0 | Card titles |
| `titleMedium` | 16px | 22px | 500 | 0 | List titles |
| `titleSmall` | 14px | 20px | 500 | +0.1px | Section headers |
| `bodyLarge` | 16px | 24px | 400 | 0 | Primary content |
| `bodyMedium` | 14px | 20px | 400 | 0 | Secondary content |
| `labelLarge` | 14px | 20px | 600 | +0.1px | Buttons |
| `labelMedium` | 12px | 16px | 500 | +0.3px | Chips, dates |
| `labelSmall` | 11px | 14px | 400 | +0.2px | Timestamps |
| `wordmark` | — | — | 600 | +0.12em | `ATLAS` logo only |

**UI typeface:** Inter (Regular 400, Medium 500, SemiBold 600).  
**Display (marketing only):** Fraunces — never in app UI body.

**Greeting accent:** 32 × 2px `#C4654A` bar — echoes logo apex.

---

## Iconography

| Property | Value |
|---|---|
| Family | Material Symbols Rounded |
| Grid | 24 × 24 dp |
| Default | `#5A6472` (outlined) |
| Active | `#C4654A` (filled) |
| Emphasis | `#1A2332` |

Custom Threshold mark reserved for brand surfaces — not navigation icons.

---

## Illustration — Architectural Void

| Rule | Value |
|---|---|
| Palette | Brand colors only, max 4 per piece |
| Shapes | Max 5 per illustration |
| Texture | Optional 3% noise overlay |
| Shadows | One soft shadow max: `#1A2332` at 6%, blur 16px |

| Scene | Metaphor |
|---|---|
| Empty places | Horizon + single dot |
| Empty procedures | Arch + void |
| Empty prices | Horizontal tag silhouette |
| Offline | Broken arch gap |
| Onboarding | Doorway + light beyond |

---

## Layout & components

### Spacing (4px base)

| Token | Value | Use |
|---|---|---|
| `xs` | 4px | Micro gaps |
| `sm` | 8px | Inline gaps |
| `md` | 12px | Chip padding |
| `lg` | 16px | Card gaps |
| `xl` | 20px | Card padding |
| `xxl` | 24px | Page horizontal (mobile) |
| `xxxl` | 28px | Primary card padding |
| `section` | 40px | Content groups |
| `sectionLarge` | 48px | Page sections |
| `pageHorizontalWide` | 48px | Tablet+ inset |
| `maxContentWidth` | 840px | Editorial column |

### Corner radius

| Token | Value | Use |
|---|---|---|
| `radiusSm` | 8px | Tags |
| `radiusMd` | 12px | Buttons, inputs |
| `radiusLg` | 16px | Cards |
| `radiusXl` | 20px | Sheets, modals |
| `radiusFull` | 999px | Pills, chips |

### Elevation

| Level | Treatment |
|---|---|
| 0 — Default | No shadow; `sandMuted` 1px border |
| 1 — Primary card | `sand` 1px border |
| 2 — Floating | `0 1px 3px rgba(26,35,50,0.06)` |
| 3 — Modal | `0 4px 16px rgba(26,35,50,0.08)` |

### Motion

| Token | Value |
|---|---|
| `durationMicro` | 150ms |
| `durationStandard` | 250ms |
| `durationEmphasis` | 400ms |
| `staggerDelay` | 60ms |
| `curveDefault` | `cubic-bezier(0, 0, 0.2, 1)` |

No bounce, elastic, or parallax on functional UI.

---

## Store visuals

- Full-bleed UI on `#FAF7F2`; no device frames
- Caption below screenshot: 20px SemiBold `#1A2332`
- Feature graphic: Threshold mark + `ATLAS` + sand horizon rule (1024 × 500)
- Screenshot sequence: Dashboard → Briefing → Procedures → Places → Prices → Privacy

---

## Asset index

```
brand/
├── figma/
│   └── design-tokens.json      # Import via Figma Tokens plugin
├── logos/
│   ├── atlas-logo-horizontal.svg
│   ├── atlas-logo-stacked.svg
│   ├── atlas-logo-reversed.svg
│   ├── atlas-mark.svg
│   └── atlas-mark-no-dot.svg
├── icons/
│   ├── atlas-app-icon.svg      # Vector source
│   └── atlas-app-icon-1024.png
├── android-adaptive/
│   ├── ic_launcher.xml
│   ├── ic_launcher_background.xml
│   └── ic_launcher_foreground.xml
└── tools/
    └── generate_app_icon.py    # Regenerates PNG from spec
```

---

## Figma library setup

1. Create Figma file **Atlas Design System**.
2. Install plugin **Tokens Studio for Figma** (formerly Figma Tokens).
3. Import `brand/figma/design-tokens.json`.
4. Create styles from tokens: Color, Text, Effect, Grid.
5. Build components per section below.

### Component library

| Component | Variants | Notes |
|---|---|---|
| Logo / Horizontal | Default, Reversed | Link SVG sources |
| Logo / Stacked | Default, Reversed | Center-aligned |
| Logo / Mark | With dot, No dot | No dot for ≤32px |
| App Icon | Light | 1024 reference frame |
| Color swatches | All tokens | Named per BRAND.md |
| Type scale | 12 styles | Inter family |
| Card | Primary, Standard, Compact | 16px radius, border only |
| Button / Filled | Default, Pressed, Disabled | 48px height |
| Button / Text | Default | Terracotta label |
| Chip / Filter | Default, Selected | Pill shape |
| Section header | With action, Without | 14px Medium muted |
| Greeting header | — | Accent bar + 3 text levels |
| Nav bar | 5 tabs | 72px height |
| Empty state | 6 scenes | Architectural void illustrations |
| Splash | Frame 1–3 | Animation keyframes |

### Grid

- Base unit: **4px**
- Layout grid: 4 columns (mobile), 8 columns (tablet), margin 24 / 48

---

## Accessibility

| Requirement | Spec |
|---|---|
| Body contrast | ≥ 7:1 (`#1A2332` on `#FAF7F2` = 12.5:1) |
| Terracotta on white | 4.6:1 — accents and buttons only |
| Touch targets | ≥ 48 × 48 dp |
| Text scaling | Support 200% without layout break |
| Motion | Respect `reduce motion` |
