## Why

O Change 3 entrega um chat funcional com `ChatWindow.vue` básico. Este change entrega um chat *vivo* — Presence em tempo real, indicador de quem está escrevendo, lobby com salas ativas, e o `ChatWindow.vue` enriquecido com animações e auto-scroll. LiveVue já resolve a tensão entre LiveView e Vue: LiveView empurra estado via props e `push_event`, Vue cuida de toda a renderização e UX do cliente.

## What Changes

- Criar `LetsChatWeb.Presence` (`use Phoenix.Presence`) e adicioná-lo à árvore de supervisão
- Ao montar `RoomLive`, registrar presença em **dois tópicos**:
  - `"room:{slug}"` com `%{name: ..., typing: false}` — quem está na sala
  - `"lobby"` com `%{room_slug: slug}` — para contagem no lobby
- `handle_info` para `presence_diff` em `"room:{slug}"`: atualizar `@participants` (lista deduplicada por `session_id`) → repassado como prop ao Vue
- **Lista de participantes** na sidebar da sala: avatares com iniciais + nome, contagem no header; presença em tempo real sem query ao banco
- **Múltiplas abas**: usar `session_id` como chave da Presence — múltiplas conexões do mesmo usuário são agrupadas sob a mesma chave, participante aparece uma única vez
- **Lobby real-time**: `LobbyLive` subscreve ao tópico `"lobby"`; ao receber `presence_diff`, recalcula `%{room_slug => count}` dos metadados — uma subscrição única atualiza todas as contagens; salas com count > 0 exibem badge **ativa**
- **Typing indicator**:
  - Input do Vue dispara evento ao LiveView a cada keystroke
  - LiveView cancela timer anterior (ref em assigns), chama `Presence.update(typing: true)`, agenda `Process.send_after(self(), {:clear_typing, session_id}, 3_000)`
  - Ao disparar `:stop_typing` ou ao enviar mensagem: `Presence.update(typing: false)`, cancela timer
  - `handle_info` para `presence_diff`: extrai lista `@typing_users` dos metadados → prop para Vue
  - Animação CSS pura (três pontos com `@keyframes bounce`); aparece/desaparece com transição — sem Vue separado, direto no `ChatWindow.vue`
- **`ChatWindow.vue` enriquecido** (sobre a versão funcional do Change 3):
  - `TransitionGroup` com `slide-in` para cada nova mensagem recebida via `handleEvent`
  - Auto-scroll suave: `nextTick(() => scrollToBottom())` após inserir nova mensagem
  - Textarea com `auto-resize`: ajusta `height` em `input` event via `el.style.height`
  - Exibe typing indicator inline abaixo da última mensagem quando `typingUsers` prop não estiver vazio

## Decisions

- **Dois tópicos de Presence (`room` + `lobby`)**: separa responsabilidades — sala rastreia quem está presente e typing; lobby rastreia apenas onde cada um está (room_slug no meta) para contagens; evita O(N salas) subscriptions no lobby
- **`session_id` como chave de Presence**: múltiplas abas do mesmo usuário agrupadas — participante aparece uma vez na lista; `length(metas)` disponível se quisermos indicar multi-tab no futuro
- **Typing indicator sem Vue separado**: animação dos três pontos é CSS puro (`@keyframes`) dentro do `ChatWindow.vue` existente — sem overhead de componente extra; a lógica de debounce fica no LiveView (Process.send_after cancelável)
- **Presença via padrão híbrido (prop inicial + `push_event` para updates)**: idêntico ao padrão de mensagens do Change 3 — estado inicial como prop no mount; `presence_diff` dispara `push_event("presence_update", %{participants: [...], typing_users: [...]})` e Vue atualiza reativamente via `handleEvent`; mantém consistência com a camada de mensagens e permite que Vue reaja sem re-render LiveView

## Capabilities

### New Capabilities

- `presence`: Rastreamento de presença por sala e no lobby via Phoenix.Presence; metadados de `typing`; contagens em tempo real no lobby

### Modified Capabilities

- `rooms`: Lobby exibe badge ativa/inativa com contagem real via Presence
- `chat-ux`: `ChatWindow.vue` enriquecido com animações de entrada, auto-scroll, textarea crescente e typing indicator integrado

## Impact

- `lib/lets_chat_web/presence.ex` — novo módulo `LetsChatWeb.Presence`
- `lib/lets_chat/application.ex` — adicionar `LetsChatWeb.Presence` à árvore de supervisão
- `lib/lets_chat_web/live/room_live.ex` — Presence.track nos dois tópicos, handle_info para diffs, debounce de typing com timer cancelável
- `lib/lets_chat_web/live/lobby_live.ex` — subscrição ao tópico `"lobby"`, recálculo de contagens por sala
- `assets/vue/ChatWindow.vue` — TransitionGroup, auto-scroll, textarea resize, typing indicator com CSS animation
- Sem migrações — Presence é 100% em memória
