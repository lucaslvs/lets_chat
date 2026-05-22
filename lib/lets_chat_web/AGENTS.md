# Web Layer — UI Guidelines

This directory contains all Phoenix web layer code: LiveViews, components, templates, and layouts.

## Design System

This project uses a **Kraken-inspired design system** layered on top of daisyUI.
daisyUI coexists — the design system is **additive**. Apply Kraken tokens for all new components.

Full spec: [`.agents/docs/design-system.md`](../../.agents/docs/design-system.md)

### Colors — quick reference

| Use | Value |
|-----|-------|
| CTA / links / brand | `#7132f5` |
| Button border / outlined | `#5741d8` |
| Primary text | `#101114` |
| Secondary / muted text | `#9497a9` |
| Surface | `#ffffff` |
| Subtle purple bg | `rgba(133,91,251,0.16)` |

### Typography — quick reference

- Headings: `Kraken-Brand`, `font-bold` (700), negative letter-spacing (`-0.5px` to `-1px`)
- Body / UI: `Kraken-Product`, fallback `Helvetica Neue`
- Buttons: 16px, weight 500–600

### Buttons — quick reference

```
Primary:  bg-[#7132f5] text-white rounded-xl px-4 py-[13px] text-base font-medium
Outlined: bg-white text-[#5741d8] border border-[#5741d8] rounded-xl px-4 py-[13px]
Subtle:   bg-[rgba(133,91,251,0.16)] text-[#7132f5] rounded-xl p-2
```

**Never** use fully-rounded pill buttons — `rounded-xl` (12px) is the max for buttons.

### Shadows

- Cards / panels: `shadow-[rgba(0,0,0,0.03)_0px_4px_24px]`
- Micro: `shadow-[rgba(16,24,40,0.04)_0px_1px_4px]`
