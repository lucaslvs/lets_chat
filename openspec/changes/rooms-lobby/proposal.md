## Why

Antes de qualquer chat acontecer, os usuários precisam de um lugar para descobrir salas existentes e criar as suas próprias. Este change estabelece a entidade `Room` e toda a experiência de navegação — lobby, criação e roteamento — sem real-time ainda. Cobre apenas salas públicas; salas privadas ficam para o Change 5.

## What Changes

- Criar o domínio Ash `LetsChat.Chat` e registrá-lo em `config/config.exs` (`ash_domains`)
- Criar o recurso Ash `Room` com os campos: `id`, `name` (display), `slug` (único, URL-safe, auto-gerado), `visibility` (`:public | :private`, default `:public`), `owner_session_id`, `owner_user_id` (nullable — preparado para Change 5), `inserted_at`
- Geração de slug: `name` → lowercase → remover caracteres especiais → espaços viram hífens (ex: "Elixir Study Group!" → `elixir-study-group`)
- Validação em tempo real via `phx-change` com debounce: ao digitar o nome, gerar slug e verificar disponibilidade no banco — exibir `✓ disponível` ou `✗ já em uso` inline, antes do submit
- **Lobby LiveView** (`/rooms`): lista salas públicas ordenadas por `inserted_at DESC`; cada card exibe `name`, `slug` e timestamp relativo ("há 5 minutos"); empty state com CTA "Criar a primeira sala" quando vazio; sem badge de ativo/inativo (real-time vem no Change 4)
- **Criação via modal no lobby**: botão "Nova sala" no header do lobby abre modal com formulário (nome + preview de slug); "Criar sala" do home navega para `/rooms` com modal já aberto via query param `?new=true`; após criação redireciona para `/rooms/:slug`
- **Room shell** (`/rooms/:slug`): layout completo com header (nome da sala + botão Sair), área de mensagens vazia com empty state, sidebar de participantes placeholder, e **input de mensagem visível mas desabilitado** — estrutura HTML/CSS final para que o Change 3 apenas adicione lógica, sem retrabalho de layout
- Guard: sem guest session, redirecionar para `/?return_to=<destino>` (mesmo padrão do Change 1)

## Decisions

- **Modelo A (name + slug separados)**: `name` é o display ("Elixir Study Group"), `slug` é o identificador de URL (`elixir-study-group`) — gerado automaticamente, editável pelo usuário antes de criar
- **Modal no lobby (não página separada)**: criação de sala é uma ação contextual do lobby; a URL `/rooms?new=true` permite deep-link direto para o modal (ex: botão "Criar sala" da home)
- **Input visível e desabilitado no shell**: define o layout final agora, evita retrabalho de estrutura no Change 3; estado desabilitado é honesto sobre a funcionalidade ainda não existir
- **Timestamp relativo no lobby**: entrega valor real (`inserted_at`) sem fingir ter presença ao vivo; Change 4 substitui por contagem de membros em tempo real
- **`owner_user_id` nullable desde já**: evita migração adicional no Change 5; não é usado em nenhuma lógica do Change 2
- **`visibility` criado mas restrito**: campo existe no banco desde esta migração, mas o formulário só permite `:public` — Change 5 abre o gate para `:private`

## Capabilities

### New Capabilities

- `rooms`: Entidade Room (name, slug, visibility, owner), geração e validação de slug, criação via modal, listagem no lobby com timestamp relativo, shell com layout completo

### Modified Capabilities

*(nenhuma — sem specs existentes)*

## Impact

- `config/config.exs` — adicionar `LetsChat.Chat` em `ash_domains`
- `lib/lets_chat/chat.ex` — novo domínio Ash `Chat`
- `lib/lets_chat/chat/room.ex` — novo recurso Ash `Room`
- `lib/lets_chat_web/live/lobby_live.ex` — novo LiveView `/rooms` com modal de criação
- `lib/lets_chat_web/live/room_live.ex` — novo LiveView `/rooms/:slug` (shell com layout completo)
- `lib/lets_chat_web/router.ex` — novas rotas dentro de `ash_authentication_live_session`
- `lib/lets_chat_web/live_user_auth.ex` — reutilizar guard `require_guest_name` do Change 1
- `priv/repo/migrations/` — nova migração para tabela `rooms`
