---
name: design-system
description: Kraken-inspired design system tokens and component specs for Let's Chat. Consult this when building or modifying any UI component.
---

# Design System — Let's Chat

daisyUI is present and coexists. This design system is **additive** — apply these tokens and patterns for all new components. Do not fight daisyUI; apply Kraken tokens on top.

## Colors

### Primary
| Token | Value | Role |
|-------|-------|------|
| Kraken Purple | `#7132f5` | CTAs, links, brand accent |
| Purple Dark | `#5741d8` | Button borders, outlined variants |
| Purple Deep | `#5b1ecf` | Deepest accent |
| Purple Subtle | `rgba(133,91,251,0.16)` | Subtle button/badge backgrounds |

### Neutral
| Token | Value | Role |
|-------|-------|------|
| Near Black | `#101114` | Primary text |
| Cool Gray | `#686b82` | Secondary text, borders at 24% opacity |
| Silver Blue | `#9497a9` | Muted/placeholder text |
| White | `#ffffff` | Primary surface |
| Border Gray | `#dedee5` | Dividers |

### Semantic
| Token | Value | Role |
|-------|-------|------|
| Green | `#149e61` | Success — use at 16% opacity for badge bg |
| Green Dark | `#026b3f` | Success badge text |

## Typography

Font families:
- **Display**: `Kraken-Brand`, fallback: `IBM Plex Sans, Helvetica, Arial`
- **UI / Body**: `Kraken-Product`, fallback: `Helvetica Neue, Helvetica, Arial`

| Role | Font | Size | Weight | Line Height | Letter Spacing |
|------|------|------|--------|-------------|----------------|
| Display Hero | Kraken-Brand | 48px | 700 | 1.17 | -1px |
| Section Heading | Kraken-Brand | 36px | 700 | 1.22 | -0.5px |
| Sub-heading | Kraken-Brand | 28px | 700 | 1.29 | -0.5px |
| Feature Title | Kraken-Product | 22px | 600 | 1.20 | normal |
| Body | Kraken-Product | 16px | 400 | 1.38 | normal |
| Body Medium | Kraken-Product | 16px | 500 | 1.38 | normal |
| Button | Kraken-Product | 16px | 500–600 | 1.38 | normal |
| Caption | Kraken-Product | 14px | 400–700 | 1.43–1.71 | normal |
| Small | Kraken-Product | 12px | 400–500 | 1.33 | normal |

## Buttons

| Variant | Background | Text | Border | Radius | Padding |
|---------|-----------|------|--------|--------|---------|
| Primary | `#7132f5` | `#ffffff` | — | 12px | 13px 16px |
| Outlined | `#ffffff` | `#5741d8` | `1px solid #5741d8` | 12px | 13px 16px |
| Subtle | `rgba(133,91,251,0.16)` | `#7132f5` | — | 12px | 8px |
| White | `#ffffff` | `#101114` | shadow | 10px | — |
| Gray | `rgba(148,151,169,0.08)` | `#101114` | — | 12px | — |

Tailwind examples:
```
Primary:  class="bg-[#7132f5] text-white rounded-xl px-4 py-[13px] text-base font-medium"
Outlined: class="bg-white text-[#5741d8] border border-[#5741d8] rounded-xl px-4 py-[13px]"
Subtle:   class="bg-[rgba(133,91,251,0.16)] text-[#7132f5] rounded-xl p-2"
```

## Badges

| Variant | Background | Text | Radius |
|---------|-----------|------|--------|
| Success | `rgba(20,158,97,0.16)` | `#026b3f` | 6px |
| Neutral | `rgba(104,107,130,0.12)` | `#484b5e` | 8px |

## Elevation / Shadows

- Subtle (cards, panels): `rgba(0,0,0,0.03) 0px 4px 24px`
- Micro (inputs, small elements): `rgba(16,24,40,0.04) 0px 1px 4px`

## Spacing Scale

`1 2 3 4 5 6 8 10 12 13 15 16 20 24 25` (px)

## Border Radius Scale

`3 6 8 10 12 16` px, `9999px` (full pill — buttons never use this), `50%` (avatars)

## Responsive Breakpoints

`375 425 640 768 1024 1280 1536` (px)

## Do's and Don'ts

**Do:**
- Use `#7132f5` for all CTAs, links, and primary actions
- Apply `12px` radius on all buttons — it's the defining shape of the system
- Use Kraken-Brand for headings, Kraken-Product for body and UI text
- Use whisper-level shadows — never harsh drop shadows

**Don't:**
- Never use pill/full-rounded buttons — 12px max
- Never use purples outside `#7132f5`, `#5741d8`, `#5b1ecf`, or the subtle rgba
- Never use harsh or colored shadows
