# App Shell Spec

## Purpose

Defines how Vue components are mounted and wired into Phoenix LiveViews. Covers the architectural decision to use isolated Vue apps per LiveView page (rather than a persistent `v-inject` shell), and the `shared_props` mechanism that automatically injects socket assigns into every Vue component.

---

## Requirements

### Requirement: Isolated Vue app per LiveView page
> **Implementation note:** The original plan was a persistent `AppShell.vue` via `v-inject` in `root.html.heex`. During implementation a Vue reactivity bug was found in the `v-inject` mechanism: the AppShell render function does not track slot key mutations, causing a blank screen when navigating from a LiveView without `v-inject` to one with `v-inject`. Decision: each LiveView mounts its own isolated Vue app directly in `@inner_content` — no `v-inject`, no persistent container. `AppShell.vue` was created and remains in `assets/vue/layouts/` for potential future use, but is NOT wired into `root.html.heex`.

Each LiveView page SHALL render its Vue component directly via `<.vue v-component="ComponentName" />` without `v-inject`. Each navigation mounts a fresh isolated Vue app. `AppShell.vue` EXISTS in `assets/vue/layouts/AppShell.vue` but is NOT wired into `root.html.heex`.

#### Scenario: Each page mounts its own Vue app
- **WHEN** a user navigates from `/` to `/rooms` via a LiveView `push_navigate`
- **THEN** a new isolated Vue app for `RoomLobby.vue` mounts inside `@inner_content`; the previous `GuestOnboarding.vue` app is unmounted

#### Scenario: shared_props are available in every Vue component
- **WHEN** `config :live_vue, :shared_props, [:current_user, :current_guest]` is set
- **THEN** every `<.vue>` component SHALL receive `current_user` and `current_guest` as props automatically without explicit prop threading in the template

---

### Requirement: shared_props configuration
The system SHALL configure `config :live_vue, :shared_props, [:current_user, :current_guest]` in `config/config.exs`. This causes LiveVue to automatically inject `current_user` and `current_guest` socket assigns as props into every `<.vue>` component rendered in a LiveView, eliminating manual prop threading for identity data. Vue components SHALL declare these props as `current_user` and `current_guest` (snake_case) — LiveVue serializes Elixir atom keys as-is, without camelCase conversion.

#### Scenario: current_guest is available as prop in any Vue component
- **WHEN** a LiveView socket has `current_guest` assigned
- **THEN** any `<.vue>` component rendered within that LiveView SHALL receive `current_guest` as a prop without it being explicitly listed in the `<.vue>` tag

#### Scenario: Props are null-safe when assigns are absent
- **WHEN** a `<.vue>` component is rendered in a context where `current_user` or `current_guest` is not set
- **THEN** the corresponding prop SHALL arrive as `nil` (serialized as JSON `null`) without raising an error

---

## Test Requirements

### Requirement: Isolated Vue app per LiveView page

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Each page mounts its own Vue app | LiveViewTest | `HomeLiveTest`, `LobbyLiveTest`, `RoomLiveTest` | `get_vue(view, name: "GuestOnboarding")` / `get_vue(view, name: "RoomLobby")` / `get_vue(view, name: "RoomShell")` confirms each LiveView mounts its isolated Vue component |

### Requirement: shared_props configuration

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| current_guest is available as prop in any Vue component | LiveViewTest | any LiveView test | Use `LiveVue.Test.get_vue/2` and check props map includes `"current_guest"` key |
| Props are null-safe when assigns are absent | LiveViewTest | `HomeLiveTest` | `HomeLive` has no `current_user` in socket by default; tests pass without error, confirming null-safety |
