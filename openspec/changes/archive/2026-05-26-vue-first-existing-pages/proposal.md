## Why

LiveVue está configurado e funcionando no projeto, mas os três templates de produção (`HomeLive`, `LobbyLive`, `RoomLive`) são HEEx puro — violando a regra estabelecida de "Vue-first para toda UI interativa". Perdemos os ganhos reais do LiveVue (reatividade local sem round-trip, animações declarativas, `useLiveForm` com touched/dirty/debounce) onde eles mais importam.

## What Changes

- Configurar `shared_props` no `config.exs` para injetar `current_user` e `current_guest` automaticamente em todo `<.vue>` — elimina threading manual de props
- Criar `AppShell.vue` com `v-inject` em `root.html.heex`: shell Vue montado uma única vez que sobrevive a navegações LiveView; hospeda estado de conexão (`useLiveConnection`) e quaisquer elementos persistentes de layout
- Criar `GuestOnboarding.vue` substituindo o template HEEx de `HomeLive`: avatar preview reativo (computed Vue a partir do campo `name`, sem round-trip), validação local, `useLiveForm` para validate/submit
- Criar `RoomLobby.vue` substituindo o template HEEx de `LobbyLive`: lista de salas, modal de criação com animação (`<Transition>`), slug preview como `computed` reativo, badge de disponibilidade do slug via `useLiveEvent`, `useLiveForm` para validate/create
- Reduzir `home_live.html.heex` e `lobby_live.html.heex` a wrappers mínimos (`<.vue v-component="..." ... />`)
- `room_live.html.heex` reduzido ao wrapper mínimo (o componente de chat será adicionado em `chat-core`)

## Capabilities

### New Capabilities

- `app-shell`: Shell Vue persistente via `v-inject` que sobrevive a navegações LiveView; gerencia estado de conexão e layout global
- `guest-onboarding-ui`: Interface de onboarding do guest com avatar preview reativo e form via `useLiveForm`
- `room-lobby-ui`: Interface do lobby com lista de salas e modal de criação animado, slug preview reativo e form via `useLiveForm`

### Modified Capabilities

- `guest-identity`: O fluxo de onboarding (nome do guest, avatar) agora é renderizado por `GuestOnboarding.vue` — os requisitos de UX do form (preview imediato do avatar, validação sem round-trip) complementam a spec existente
- `rooms`: O lobby (listagem e criação de salas) agora é renderizado por `RoomLobby.vue` — requisitos de UX do modal (animação, slug preview em tempo real) complementam a spec existente

## Impact

- `config/config.exs` — adicionar `config :live_vue, :shared_props, [:current_user, :current_guest]`
- `lib/lets_chat_web/components/layouts/root.html.heex` — adicionar `<.vue v-component="AppShell" v-inject>` wrappando o conteúdo
- `lib/lets_chat_web/live/home_live.html.heex` — reduzir a `<.vue v-component="GuestOnboarding" form={@form} />`
- `lib/lets_chat_web/live/home_live.ex` — simplificar assigns; passar form via `useLiveForm`-compatible assign
- `lib/lets_chat_web/live/lobby_live.html.heex` — reduzir a `<.vue v-component="RoomLobby" rooms={@rooms} form={@form} />`
- `lib/lets_chat_web/live/lobby_live.ex` — simplificar handles; slug_available via push_event ao invés de assign
- `lib/lets_chat_web/live/room_live.html.heex` — reduzir ao wrapper mínimo (sem componente de chat ainda)
- `assets/vue/AppShell.vue` — novo componente
- `assets/vue/GuestOnboarding.vue` — novo componente
- `assets/vue/RoomLobby.vue` — novo componente
- `assets/vue/index.ts` — registrar os três novos componentes
