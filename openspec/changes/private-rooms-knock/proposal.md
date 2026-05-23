## Why

Nem toda conversa é pública. Este change adiciona o modelo de privacidade completo: salas que só acessíveis via link de convite, e um mecanismo de "knock" para que visitantes possam solicitar entrada quando não têm o link — com notificação em tempo real para os membros presentes decidirem.

## What Changes

- Habilitar `visibility: :private` na criação de salas; ao criar sala privada, gerar `invite_token` (UUID) automaticamente
- Página pós-criação de sala privada: exibe o magic link de convite (`/rooms/:slug/join/:token`) com botão "Copiar link" e botão "Entrar agora"
- Rota de entrada via convite (`/rooms/:slug/join/:token`): valida token → concede acesso via `Phoenix.LiveView.put_session/3` (adiciona `room.id` a `:authorized_rooms`) → redireciona para a sala
- Lobby: salas privadas são **invisíveis** para não-membros — apenas membros (com acesso via token ou knock aceito) as veem na listagem
- Mecanismo de Knock (para visitantes sem token):
  - Visitante acessa `/rooms/:slug` sem acesso → `RoomLive` exibe estado `:blocked` com opção "Solicitar acesso"
  - Ao confirmar, cria registro `RoomKnock` e faz broadcast PubSub para `"room:{slug}:knock"`
  - Membros presentes na sala recebem toast: "Lucas quer entrar. [Aceitar] [Recusar]"
  - `RoomLive` do visitante entra em estado `:waiting`: subscribe em `"knock:{knock_id}"` via PubSub; agenda timeout com `Process.send_after(self(), :knock_timeout, 5 * 60 * 1000)`
  - Qualquer membro pode aceitar: broadcast para `"knock:{knock_id}"` → `handle_info` do visitante chama `put_session` com `:authorized_rooms` e redireciona para a sala
  - Qualquer membro pode recusar: broadcast para `"knock:{knock_id}"` → visitante recebe flash e volta ao lobby
  - Timeout de 5 minutos sem resposta: `handle_info(:knock_timeout)` expira o `RoomKnock` e exibe mensagem ao visitante; se o visitante fechar a aba, o timer some junto com o processo
  - Nenhum membro online: knock apenas expira após 5 minutos sem comportamento especial
- Criar recurso Ash `RoomKnock` com: `id`, `room_id`, `requester_name`, `requester_session_id`, `status` (`:pending | :accepted | :rejected | :expired`), `expires_at`

## Decisions

- **Lobby invisível para não-membros**: salas privadas não aparecem no lobby para visitantes sem acesso — elimina o estado "sala que você sabe que existe mas não pode entrar"; visitante só descobre a sala via link de convite ou URL direta
- **Token por-sala, sem expiração**: um único `invite_token` (UUID) por sala, permanente enquanto a sala existir; quem tem o link pode entrar sempre; revogação (regenerar token) fica fora do escopo deste change
- **Knock via URL direta**: o trigger do knock não é o lobby (sala invisível lá), mas sim a tentativa de acessar `/rooms/:slug` sem autorização; `RoomLive` detecta a ausência de acesso e exibe o estado `:blocked`
- **Waiting sem polling**: o visitante permanece no `RoomLive` em estado `:waiting`; a espera é gerenciada via PubSub (`"knock:{knock_id}"`) + `Process.send_after` — sem polling, sem Oban; se o visitante fechar a aba, o processo e o timer são descartados junto
- **Autorização via session**: na aceitação do knock (e na entrada via invite link), `Phoenix.LiveView.put_session/3` adiciona o `room.id` à lista `:authorized_rooms` na guest session — persiste entre reloads sem query extra
- **Timeout silencioso sem membros online**: se nenhum membro estiver presente para ver o toast, o knock simplesmente expira após 5 minutos; sem notificação diferenciada, sem fila de knocks pendentes para membros que chegarem depois
- **Status `:expired`** adicionado ao `RoomKnock`: `:pending | :accepted | :rejected | :expired` — distingue rejeição explícita de timeout
- **Query do lobby com salas privadas**: o `LobbyLive` filtra `WHERE visibility = :public OR (visibility = :private AND id IN :authorized_rooms)` — membros com acesso veem suas salas privadas com contagem real; visitantes sem acesso não as veem
- **Presence `"lobby"` para salas privadas**: usuários em salas privadas continuam registrando `%{room_slug: slug}` no tópico `"lobby"` — isso vaza a existência do slug (não o nome) para outros `LobbyLive` subscritores; aceito como tradeoff mínimo em troca de contagens corretas para membros autorizados

## Capabilities

### New Capabilities

- `private-rooms`: Criação de salas privadas, geração de invite token, acesso via magic link de convite
- `knock`: Fluxo de solicitação de acesso em tempo real — request, notificação, accept/reject, timeout

### Modified Capabilities

- `rooms`: Adiciona campo `invite_token`; habilita `visibility: :private` (campo já existe desde o Change 2); lobby filtra salas privadas para não-membros (invisíveis)

## Impact

- `lib/lets_chat/chat/room.ex` — adicionar campo `invite_token`; habilitar `:private` na action de criação (campo `visibility` já existe)
- `lib/lets_chat/chat/room_knock.ex` — novo recurso Ash
- `lib/lets_chat_web/live/room_new_live.ex` — seletor de visibilidade + tela pós-criação com link
- `lib/lets_chat_web/live/room_live.ex` — handle_info para knock events; toast de notificação
- `lib/lets_chat_web/live/lobby_live.ex` — query filtrada por `visibility = :public OR id IN authorized_rooms`; contagens de Presence incluem salas privadas para membros autorizados; diferenciação visual (ícone privado vs público)
- `lib/lets_chat_web/router.ex` — rota `/rooms/:slug/join/:token`
- `priv/repo/migrations/` — adicionar coluna `invite_token` em `rooms`; nova tabela `room_knocks`
