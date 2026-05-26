## Context

O projeto tem LiveVue configurado e funcional (`VueDemoLive` prova isso), mas os três templates de produção são HEEx puro. A mudança introduz três componentes Vue e faz ajustes mínimos nos LiveViews correspondentes para cumprir a regra "Vue-first para toda UI interativa".

**Estado atual:**
- `HomeLive`: form de onboarding (sem AshPhoenix.Form — fluxo simples de name → redirect)
- `LobbyLive`: lista de salas + modal de criação com AshPhoenix.Form + slug check síncrono
- `RoomLive`: shell estático, conteúdo de chat vem na change `chat-core`
- `root.html.heex`: `{@inner_content}` direto no `<body>`, sem shell Vue

**Constraints:**
- `HomeLive` não usa AshPhoenix.Form (form nativo simples → redirect para `/session/guest`); `useLiveForm` não se aplica
- O slug availability check em `LobbyLive` é síncrono hoje (DB query inline no `handle_event("validate")`); mover para `push_event` elimina o round-trip de validação bloqueante
- `v-inject` requer que o elemento Vue seja filho direto do `<body>` (ou de um elemento que persiste entre navegações); o layout `root.html.heex` é o único ponto adequado

## Goals / Non-Goals

**Goals:**
- `GuestOnboarding.vue` com avatar preview reativo (computed Vue, zero round-trip) e form nativo
- `RoomLobby.vue` com modal animado, slug preview reativo (computed) e badge de disponibilidade via `push_event`
- `RoomShell.vue` como shell de sala (header + container para chat-core)
- `shared_props` configurado para injetar `current_user`/`current_guest` automaticamente em todo `<.vue>`
- Templates HEEx de `HomeLive`, `LobbyLive` e `RoomLive` substituídos por componentes Vue isolados
- ~~Shell Vue persistente (`AppShell.vue`) via `v-inject`~~ — descartado (ver Decisão 1)

**Non-Goals:**
- Adicionar componente de chat ao `RoomLive` (escopo da change `chat-core`)
- Migrar autenticação ou session handling para Vue
- Adicionar Pinia ou gerenciamento de estado global

## Decisions

### 1. App Vue isolado por página (sem `v-inject`)

> **Decisão final diferiu do plano original.** O plano era usar `AppShell.vue` como container persistente em `root.html.heex` com `v-inject="app-shell"` em cada page Vue. Durante a implementação foi identificado um bug de reatividade: a render function do AppShell não rastreia mutações de slot key, causando tela em branco ao navegar de uma LiveView sem `v-inject` para uma com `v-inject`. A abordagem foi abandonada.

**Decisão implementada:** Cada LiveView monta seu próprio app Vue isolado diretamente em `@inner_content` via `<.vue v-component="ComponentName" />` — sem `v-inject`, sem container persistente em `root.html.heex`. `AppShell.vue` existe em `assets/vue/layouts/` mas não está conectado ao layout.

**Por quê:** Elimina o bug de reatividade e simplifica a arquitetura. Cada page é completamente autônoma — sem acoplamento ao container persistente. A navegação LiveView substitui `@inner_content` normalmente; Vue monta/desmonta por página como esperado.

**Plano original (descartado):** `root.html.heex` adicionaria `<.vue id="app-shell" v-component="AppShell" />` antes de `{@inner_content}`; cada page usaria `v-inject="app-shell"`. Descartado pelo bug acima. Caso o LiveVue corrija o bug em versão futura, a migração para esta abordagem é simples.

### 2. `GuestOnboarding.vue` com form nativo (não `useLiveForm`)

**Decisão:** `GuestOnboarding.vue` usa um form HTML simples com `phx-change` e `phx-submit` emitidos via `$live.pushEvent` — ou, mais simples ainda, mantém o form nativo do LiveView via `phx-change="validate"` e `phx-submit="submit"` como atributos passados ao componente.

**Por quê:** `HomeLive` não usa AshPhoenix.Form — é um redirect simples após validação do nome. `useLiveForm` foi projetado para forms Ash com changesets. Usar form nativo mantém a semântica correta e evita overhead de abstração.

**Alternativa descartada:** `useLiveForm` — não tem AshPhoenix.Form no backend; a abstração não agrega valor aqui.

**Avatar preview:** `computed` Vue puro derivado do campo `name` — sem push_event, sem round-trip. A lógica atual de `@name` no LiveView vira um `ref` local no componente.

### 3. Slug availability check via `push_event` no `LobbyLive`

**Decisão:** O `handle_event("validate")` do `LobbyLive` emite `push_event("slug_availability", %{available: bool})` ao invés de atualizar assign `slug_available`. O `RoomLobby.vue` escuta com `useLiveEvent("slug_availability", ...)` e atualiza um `ref` local.

**Por quê:** O slug preview reativo (computed Vue a partir do campo name) não precisa de round-trip. Apenas o check de disponibilidade (query no DB) precisa ir ao servidor. `push_event` desacopla o estado do componente Vue dos assigns do LiveView, eliminando re-renders desnecessários do HEEx.

**Alternativa descartada:** Manter slug_available como assign — causa re-render do wrapper HEEx a cada keystroke.

### 4. `useLiveForm` para o form de criação de sala (`RoomLobby.vue`)

**Decisão:** `LobbyLive` cria um `AshPhoenix.Form` e passa como prop `form={@form}`. `RoomLobby.vue` usa `useLiveForm(props.form, { changeEvent: "validate", submitEvent: "create_room" })`.

**Por quê:** O form de criação de sala usa AshPhoenix.Form com validação Ash — é exatamente o caso de uso de `useLiveForm`. Ganhamos touched/dirty tracking e debounce automático.

**Alternativa descartada:** Form nativo sem `useLiveForm` — perderia validação reativa e dirty tracking.

### 5. `shared_props` para injeção automática de `current_user`/`current_guest`

**Decisão:** Adicionar `config :live_vue, :shared_props, [:current_user, :current_guest]` em `config/config.exs`.

**Por quê:** Evita threading manual dessas props em cada `<.vue>`. Todo componente Vue que precise de identidade do usuário acessa via prop automaticamente injetada. É uma feature declarada do LiveVue.

**Risco:** Componentes Vue que não usam essas props recebem-nas de qualquer forma — overhead mínimo, aceitável.

### 6. `RoomLive` migrado para `RoomShell.vue` (excedeu escopo original)

> **Decisão final excedeu o plano original.** O plano era apenas reduzir `room_live.html.heex` a um wrapper estrutural mínimo em HEEx. Durante a implementação, para manter consistência arquitetural com as outras páginas (e como pré-requisito para eliminar o bug de navegação do `v-inject`), `RoomLive` foi completamente migrado para Vue.

**Decisão implementada:** `room_live.html.heex` foi deletado. Criado `assets/vue/pages/RoomShell.vue` com header (nome da sala + link "← Salas") e container `<main>` vazio para o chat (que vem em `chat-core`). `room_live.ex` renderiza `<.vue v-component="RoomShell" room={@room} />`.

**Por quê:** Consistência arquitetural — todas as páginas Vue-first. O shell estático em HEEx era o único ponto que forçava a mistura. O conteúdo de chat ainda está ausente (escopo de `chat-core`); `RoomShell.vue` é apenas o container que receberá o componente de chat.

## Risks / Trade-offs

- ~~**`v-inject` e CSP**~~ — `v-inject` não foi utilizado (ver Decisão 1); risco eliminado.

- **`shared_props` expõe dados para todos os componentes** → Se um componente Vue for incluído em contexto sem `current_user` no socket, a prop virá `nil`. Mitigação: componentes devem tratar `current_user` como nullable.

- **Slug check assíncrono (push_event) vs. submit** → O submit pode ocorrer antes do `push_event` de slug_available chegar (race condition de latência). Mitigação: o botão de submit permanece desabilitado enquanto `slugAvailable` for `null` (ainda carregando) ou `false`.

- **`useLiveForm` e o form de lobby aberto via query param `?new=true`** → O LiveView já abre o modal e cria o form no `handle_params`. Vue precisa detectar `show_modal` como prop para montar o modal na posição correta. Sem risco adicional — é apenas uma prop booleana.

## Migration Plan

1. Configurar `shared_props` em `config/config.exs` (sem risco, apenas config)
2. Criar `AppShell.vue` + atualizar `root.html.heex` (testável imediatamente em dev)
3. Criar `GuestOnboarding.vue` + simplificar `home_live.html.heex` e `home_live.ex`
4. Criar `RoomLobby.vue` + simplificar `lobby_live.html.heex` e `lobby_live.ex`
5. Reduzir `room_live.html.heex` ao wrapper mínimo
6. Registrar os três componentes em `assets/vue/index.ts`
7. Rodar `mix precommit` + verificar visualmente em dev

**Rollback:** Cada passo é reversível individualmente — os templates HEEx originais podem ser restaurados sem afetar o backend.

## Open Questions

~~**AppShell.vue: quais elementos persistentes hospedar?**~~ **Resolvido:** AppShell.vue é um wrapper passthrough `<slot />` intencionalmente mínimo. Elementos de layout global (navbar, sidebar, indicador de conexão) serão adicionados em changes futuras quando houver design definido. `useLiveConnection` e elementos persistentes estão fora do escopo desta change.
