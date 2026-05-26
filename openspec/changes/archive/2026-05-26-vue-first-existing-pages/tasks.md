## 1. Configuração inicial

- [x] 1.1 Adicionar `config :live_vue, :shared_props, [:current_user, :current_guest]` em `config/config.exs`
- [x] 1.2 Adicionar `vitest`, `@vue/test-utils` e `jsdom` como `devDependencies` em `assets/package.json` e rodar `npm install`
- [x] 1.3 Criar `assets/vitest.config.ts` com plugin Vue, environment `jsdom` e `globals: true`
- [x] 1.4 Adicionar script `"test": "vitest run"` e `"test:watch": "vitest"` em `assets/package.json`

## 2. AppShell.vue e shell persistente

- [x] 2.1 Criar `assets/vue/layouts/AppShell.vue` — componente passthrough com `<slot />` para `@inner_content`; aceita `currentUser` e `currentGuest` como props opcionais (via shared_props)
- [x] 2.2 Atualizar `lib/lets_chat_web/components/layouts/root.html.heex` — adicionar `<.vue id="app-shell" v-component="AppShell" />` antes de `{@inner_content}` (sem wrapping); cada LiveView page usa `v-inject="app-shell"` no seu próprio `<.vue>` para injetar o componente Vue dentro do container AppShell
  > **Nota de implementação:** `v-inject` não foi utilizado — bug de reatividade Vue causava tela em branco ao navegar entre LiveViews. `root.html.heex` permanece com `{@inner_content}` direto. Cada LiveView monta seu próprio app Vue isolado. Ver Decisão 1 em `design.md`.

## 3. GuestOnboarding.vue

- [x] 3.1 Criar `assets/vue/pages/GuestOnboarding.vue` com:
  - `ref` local para o campo `name` (estado client-only, não vem como prop)
  - `computed` `avatarInitials` — até 2 iniciais a partir de `name` (mirror de `avatar_initials/1`)
  - `computed` `avatarColor` — cor determinística de `name` via hash (mirror de `avatar_color/1`); retorna `"?"` quando `name` está vazio
  - Form com `phx-change="validate"` e `phx-submit="submit"` disparando para o LiveView
  - Prop `error` (string | nil) recebida do LiveView para exibir erro inline
  - Props `returnTo` e `guestSessionId` recebidas e incluídas como hidden inputs no form
- [x] 3.2 Deletar `lib/lets_chat_web/live/home_live.html.heex` e adicionar `render/1` com `~H` diretamente em `home_live.ex` — renderiza `<.vue v-component="GuestOnboarding" v-inject="app-shell" return_to={@return_to} guest_session_id={@guest_session_id} error={@error} />`
- [x] 3.3 Simplificar `lib/lets_chat_web/live/home_live.ex` — remover assign `name` (agora estado local Vue); manter `return_to`, `guest_session_id`, `error`; manter handlers `validate` e `submit` inalterados

## 4. RoomLobby.vue

- [x] 4.1 Criar `assets/vue/pages/RoomLobby.vue` com:
  - Prop `rooms` (array de objetos com `name`, `slug`, `insertedAt`) — renderiza lista de cards
  - Empty state quando `rooms` é vazio
  - Prop `showModal` (boolean) — controla visibilidade do modal
  - Prop `form` — passado para `useLiveForm(props.form, { changeEvent: "validate", submitEvent: "create_room" })`
  - `computed` `slugPreview` — aplica `slugify` local ao campo `name` do form (sem round-trip)
  - `ref` `slugAvailable` (null | boolean) — inicia `null` quando `slugPreview` muda, atualizado via `useLiveEvent("slug_availability", handler)`
  - Modal com `<Transition>` para animação de entrada/saída; auto-foca input de nome ao abrir
  - Botões "Nova sala" e "Cancelar" que disparam `open_modal` / `close_modal` via `$live.pushEvent`
  - Click no backdrop dispara `close_modal`
  - Botão de submit desabilitado quando `slugAvailable` é `null` ou `false`
  - Computed `relativeTime` para exibir timestamp humano a partir de `insertedAt`
- [x] 4.2 Atualizar `lib/lets_chat_web/live/lobby_live.ex`:
  - Remover assigns `slug_preview` e `slug_available` (agora estado local Vue)
  - No `handle_event("validate", ...)`: substituir `assign(socket, slug_preview: ..., slug_available: ...)` por `push_event(socket, "slug_availability", %{available: slug_available?(...)})`
  - Manter todos os outros handlers (`open_modal`, `close_modal`, `create_room`) inalterados
- [x] 4.3 Deletar `lib/lets_chat_web/live/lobby_live.html.heex` e adicionar `render/1` com `~H` diretamente em `lobby_live.ex` — renderiza flash components HEEx + `<.vue v-component="RoomLobby" v-inject="app-shell" rooms={@rooms} form={@form} show_modal={@show_modal} />`
- [x] 4.4 Remover função privada `time_ago/1` de `lobby_live.ex` (lógica migrada para Vue computed)

## 5. RoomLive — wrapper mínimo

- [x] 5.1 Reduzir `lib/lets_chat_web/live/room_live.html.heex` ao wrapper estrutural mínimo — remover placeholder de input desabilitado e conteúdo de UI interativa; manter apenas estrutura de layout (header com nome da sala e link "← Salas", container `main` vazio)
  > **Nota de implementação:** Excedeu escopo original. `room_live.html.heex` foi deletado e criado `assets/vue/pages/RoomShell.vue` com a mesma estrutura (header + main vazio). `room_live.ex` renderiza `<.vue v-component="RoomShell" room={@room} />`. Ver Decisão 6 em `design.md`.

## 6. Testes ExUnit — integração LiveVue

- [x] 6.1 Atualizar `test/lets_chat_web/live/home_live_test.exs` — adicionar assertions com `LiveVue.Test.get_vue(view, name: "GuestOnboarding")` para verificar props `error`, `returnTo`, `guestSessionId`; atualizar cenário de "avatar preview" para verificar que não há assign `name` no socket (estado migrou para Vue)
- [x] 6.2 Atualizar `test/lets_chat_web/live/lobby_live_test.exs` — substituir assertions de HTML de slug preview/availability por verificação de `push_event` emitido; adicionar `LiveVue.Test.get_vue(view, name: "RoomLobby")` para verificar props `rooms`, `showModal`, `form`
- [x] 6.3 Verificar `test/lets_chat_web/live/room_live_test.exs` — confirmar que testes existentes passam com o template reduzido; atualizar seletores de HTML quebrados se necessário

## 7. Testes Vitest — unitários de componente Vue

- [x] 7.1 Criar `assets/vue/__tests__/GuestOnboarding.spec.ts` — testar computed `avatarInitials` (nome vazio → "?", palavra única → inicial, múltiplas palavras → 2 iniciais) e computed `avatarColor` (mesmo nome → mesma cor)
- [x] 7.2 Criar `assets/vue/__tests__/RoomLobby.spec.ts` — testar computed `slugPreview` (campo vazio → null, nome com espaços → slug com hífens, caracteres especiais → sanitizados)

## 8. Verificação

- [x] 8.1 Rodar `mix compile` e resolver erros de compilação
- [x] 8.2 Verificar em dev que `AppShell.vue` monta e **não** é remontado ao navegar entre `/` → `/rooms` → `/rooms/:slug` — N/A (AppShell não wired por design); navegação LiveView sem full reload confirmada via playwright
- [x] 8.3 Verificar em dev que avatar preview em `GuestOnboarding.vue` atualiza em cada keystroke sem round-trip (checar Network tab — sem requests ao digitar)
- [x] 8.4 Verificar em dev que modal de `RoomLobby.vue` abre e fecha com animação CSS e que slug preview atualiza sem round-trip
- [x] 8.5 Rodar `mix test` e confirmar que todos os testes ExUnit passam
- [x] 8.6 Rodar `npm test --prefix assets` e confirmar que todos os testes Vitest passam
- [x] 8.7 Rodar `mix precommit` e resolver issues pendentes
