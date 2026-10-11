# Canyons Connect — Design System

A small, strict system. Everything here is enforced in code via tokens
(`lib/core/theme/`) and approved components (`lib/design_system/`). Components
read **roles**, never raw hex.

## Foundations

### Spacing — `Space` (`dimens.dart`)
8px base unit. Every gap/padding snaps to: **4 / 8 / 16 / 24 / 32 / 48**.
24px between related blocks, 48px between major sections. No arbitrary values.

### Grid & layout — `Layout`
Max content width **1200px**; readable (long-form) width 720px. Responsive
breakpoints at 640 / 905. One focal element per screen; at most one primary
action per view.

### Typography — `AppType`
Fixed scale, nothing in between: **14 / 16 / 20 / 24 / 32**.
Two weights only: **400** body, **600** headings.
Line height **1.5** body, **1.2** headings. Sentence case for UI labels, title
case for headings.

### Color — `AppColors` (ThemeExtension, light + dark)
- Neutral background `#F5F5F5` (dark `#121212`), surfaces and borders via tokens.
- **Exactly one accent:** `#2563EB` (light) / `#60A5FA` (dark). No secondary
  brand highlights.
- Flat fills only — no gradients, no glows.
- Status roles (danger/success/warning) exist **only** for small semantic
  indicators (overdue, urgent, connected), never as decorative fills.

**Contrast — all pairs meet WCAG AA (≥4.5:1):**

| Pair (light) | Ratio |
|---|---|
| textPrimary `#1A1A1A` on surface `#FFFFFF` | ~16:1 |
| textSecondary `#525252` on `#FFFFFF` | ~7.8:1 |
| textTertiary `#707070` on `#FFFFFF` | ~5.0:1 |
| accent `#2563EB` / white | ~5.2:1 |
| danger `#DC2626` / white | ~4.8:1 |
| success `#15803D` / white | ~5.0:1 |
| warning `#B45309` / white | ~5.0:1 |

Dark-mode tokens are tuned to the same ≥4.5:1 bar against `#121212`.

### Elevation & shape
Shadows **0–2px**, elevation only (never decorative). Border radius **≤4px**
(`Radii.md = 4`, `Radii.sm = 2`). No pills, no over-rounded cards, no
glassmorphism. Avatars use a rounded-square (radius 4), not a circle, to honor
the rule.

## Components (`lib/design_system/`)

Approved components only — no one-off UI. Each interactive component defines the
full state set: **default, hover, focus, active, disabled, loading, error,
empty**, with a visible keyboard focus ring.

- `AppButton` — primary / secondary / tertiary (+ small size, destructive)
- `AppCard` — flat surface, hairline border, interactive variant with states
- `AppChip` — tags / filters (neutral + semantic tones)
- `AppSegmented` — in-view tabs
- `AppProgressBar`, `AppAvatar`, `SectionHeader`
- `EmptyState`, `ErrorStateView`, `LoadingStateView`, `Skeleton` / `SkeletonList`

## The banned list
Generic SaaS styling, excessive gradients, purple glows, glassmorphism,
over-rounded cards, arbitrary shadow/spacing values, pill shapes, decorative
drop shadows.

## Self-test (Strategy 7)
Describe a screen in numbers before shipping:

> ✅ "8px grid, 24px between sections, single blue accent #2563EB, 4px radius,
> flat fills."
> ❌ "it looks clean and modern and premium" → warning sign, it's generic.

## Normalization checklist (before handoff)
- [x] Colors mapped to tokens (no ad-hoc hex in components)
- [x] Spacing snapped to the 4/8px grid
- [x] Shadows on the 0–2px elevation scale
- [x] Type sizes on the 14/16/20/24/32 scale
- [x] All component states present
- [x] Contrast verified against WCAG AA
- [x] Light + dark token sets
```
