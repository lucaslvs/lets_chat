## Why

Este é o change que torna o app utilizável de verdade: usuários em uma mesma sala conseguem se comunicar em tempo real. Após este change existe algo concreto para mostrar e testar com outras pessoas. O foco é na entrega de mensagens de forma correta e confiável — polish e presença avançada ficam para o Change 4.

## What Changes

- Criar o recurso Ash `Message` com os campos: `id`, `room_id`, `sender_name`, `session_id`, `content`, `type` (`:text | :system`, default `:text`), `inserted_at` — sem `sender_avatar` (computado do `sender_name` no display)
- Eventos de sistema **persistidos**: ao montar/desmontar `RoomLive`, criar `Message` com `type: :system` e `content: "fulano entrou na sala"` / `"fulano saiu"` — aparecem no histórico mesmo após reload
- No `mount`, carregar as últimas 100 mensagens (`:chat` e `:system`) ordenadas por `inserted_at ASC` e passá-las como prop ao `ChatWindow.vue` via `assign(:messages, messages)`
- Ao receber broadcast de nova mensagem via PubSub, usar `push_event(socket, "new_message", serialize(message))` — apenas o novo item trafega no wire (O(1)), sem repassar a lista completa
- **`ChatWindow.vue`** (versão funcional, sem animações): recebe `@messages` como prop inicial; escuta `handleEvent("new_message")` e faz `messages.value.push(msg)`; renderiza a lista; Enter sem Shift envia, Shift+Enter quebra linha — tudo dentro do componente Vue
- **Agrupamento visual**: no template Vue, comparar `message.session_id` com o item anterior — mensagens consecutivas do mesmo remetente ocultam avatar e nome repetidos
- Diferenciação visual: mensagens próprias (`sessionId === currentUser.sessionId`) alinhadas à direita; mensagens de outros à esquerda; eventos de sistema centralizados em tom neutro
- Tratamento de sala inexistente: slug desconhecido redireciona para `/rooms` com flash informativo

## Decisions

- **Eventos de sistema persistidos**: join/leave aparecem no histórico completo da sala, mesmo para quem entra depois — comportamento mais informativo que efêmero; a mesma tabela `messages` serve com `type: :system`
- **Sem `sender_avatar` no banco**: avatar é computado de `sender_name` no display (`initials/1` + `avatar_color/1` do Change 1) — sem sincronização de estado, sem campo extra
- **`push_event` em vez de LiveView Streams**: LiveVue permite que o Vue receba a lista inicial via prop e atualizações incrementais via `handleEvent` — O(1) no wire sem MutationObserver; o Vue gerencia o DOM da timeline inteiro
- **ChatWindow.vue desde o Change 3**: entregar o componente funcional agora evita migração de Streams → Vue no Change 4; o Change 4 só enriquece o componente com animações e scroll
- **Broadcast do struct completo**: mensagens não são editadas; enviar `%Message{}` direto via PubSub evita query extra nos receivers; `push_event` serializa para JSON antes de enviar ao Vue
- **Agrupamento no Vue**: lógica de display no template Vue — comparação index-based durante o render; zero impacto no modelo de dados

## Capabilities

### New Capabilities

- `messages`: Persistência de mensagens (`:text`) e eventos de sistema (`:system`); histórico inicial como prop; entrega incremental em tempo real via `push_event`; agrupamento visual por remetente consecutivo

### Modified Capabilities

- `rooms`: Shell da sala ativado — input habilitado, `ChatWindow.vue` conectado ao PubSub via LiveView

## Impact

- `lib/lets_chat/chat/message.ex` — novo recurso Ash com campo `type`
- `lib/lets_chat/chat.ex` — adicionar `Message` ao domínio `Chat`
- `lib/lets_chat_web/live/room_live.ex` — mount com assign inicial, handle_event send, handle_info com push_event, eventos de sistema no mount/unmount
- `assets/vue/ChatWindow.vue` — novo componente Vue (funcional, sem animações)
- `priv/repo/migrations/` — migração para tabela `messages`
- Sem novos processos OTP — PubSub (`LetsChat.PubSub`) já existe na árvore de supervisão
