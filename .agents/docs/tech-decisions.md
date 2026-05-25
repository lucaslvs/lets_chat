---
name: tech-decisions
description: Architectural and library adoption decisions for Let's Chat. Consult this before building any new feature to follow the project's intended patterns.
---

# Tech Decisions — Let's Chat

## Frontend: Vue-First

**Rule:** All new UI components and pages must be built with Vue (via LiveVue). HEEx is for layouts and minimal wrappers only.

**Why:** LiveVue was chosen from the start to enable rich, reactive UIs. Agents defaulting to HEEx-only is the wrong direction, even though most existing code is still in HEEx.

**How to apply:**
- New LiveView templates → mount a Vue component via `<.vue>`, keep HEEx minimal
- New interactive UI (forms, lists, real-time updates) → Vue component in `assets/vue/`
- Existing HEEx templates → leave as-is unless explicitly asked to migrate
- When asked to migrate a screen → convert the full template to Vue

Consult `.agents/docs/design-system.md` for tokens and component specs when building Vue UI.
