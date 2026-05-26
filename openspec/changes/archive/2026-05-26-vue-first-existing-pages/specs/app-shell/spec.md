## ADDED Requirements

### Requirement: Isolated Vue app per LiveView page
> **Nota de implementação:** A abordagem original era um `AppShell.vue` persistente via `v-inject` em `root.html.heex`. Durante a implementação, foi identificado um bug de reatividade Vue no mecanismo `v-inject`: a render function do AppShell não rastreia mutações de slot key, causando tela em branco ao navegar de uma LiveView sem `v-inject` para uma com `v-inject`. Decisão: cada LiveView monta seu próprio app Vue isolado diretamente em `@inner_content` — sem `v-inject`, sem container persistente. `AppShell.vue` foi criado e permanece em `assets/vue/layouts/` para uso futuro, mas não está conectado ao `root.html.heex`.

Each LiveView page SHALL render its Vue component directly via `<.vue v-component="ComponentName" />` without `v-inject`. Each navigation mounts a fresh isolated Vue app. `AppShell.vue` EXISTS in `assets/vue/layouts/AppShell.vue` but is NOT wired into `root.html.heex`.

#### Scenario: Each page mounts its own Vue app
- **WHEN** a user navigates from `/` to `/rooms` via a LiveView `push_navigate`
- **THEN** a new isolated Vue app for `RoomLobby.vue` mounts inside `@inner_content`; the previous `GuestOnboarding.vue` app is unmounted

#### Scenario: shared_props are available in every Vue component
- **WHEN** `config :live_vue, :shared_props, [:current_user, :current_guest]` is set
- **THEN** every `<.vue>` component SHALL receive `current_user` and `current_guest` as props automatically without explicit prop threading in the template

### Requirement: shared_props configuration
The system SHALL configure `config :live_vue, :shared_props, [:current_user, :current_guest]` in `config/config.exs`. This causes LiveVue to automatically inject `current_user` and `current_guest` socket assigns as props into every `<.vue>` component rendered in a LiveView, eliminating manual prop threading for identity data. Vue components SHALL declare these props as `current_user` and `current_guest` (snake_case) — LiveVue serializes Elixir atom keys as-is, without camelCase conversion.

#### Scenario: current_guest is available as prop in any Vue component
- **WHEN** a LiveView socket has `current_guest` assigned
- **THEN** any `<.vue>` component rendered within that LiveView SHALL receive `current_guest` as a prop without it being explicitly listed in the `<.vue>` tag

#### Scenario: Props are null-safe when assigns are absent
- **WHEN** a `<.vue>` component is rendered in a context where `current_user` or `current_guest` is not set
- **THEN** the corresponding prop SHALL arrive as `nil` (serialized as JSON `null`) without raising an error

## Test Requirements

### Requirement: Isolated Vue app per LiveView page

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| Each page mounts its own Vue app | LiveViewTest | `HomeLiveTest`, `LobbyLiveTest`, `RoomLiveTest` | `get_vue(view, name: "GuestOnboarding")` / `get_vue(view, name: "RoomLobby")` / `get_vue(view, name: "RoomShell")` confirma que cada LiveView monta seu componente Vue isolado |

### Requirement: shared_props configuration

| Scenario | Test type | Module | Notes |
|---|---|---|---|
| current_guest is available as prop in any Vue component | LiveViewTest | any LiveView test | Use `LiveVue.Test.get_vue/2` and check props map includes `"current_guest"` key |
| Props are null-safe when assigns are absent | LiveViewTest | `HomeLiveTest` | `HomeLive` não tem `current_user` no socket por padrão; testes passam sem erro, confirmando null-safety |
