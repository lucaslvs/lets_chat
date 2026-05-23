## Why

O app precisa de um ponto de entrada sem fricção — ninguém deve criar conta para começar a conversar. Mas a identidade precisa persistir durante a sessão e, opcionalmente, ser vinculada a uma conta real para quem quiser histórico permanente. Esta é a fundação sobre a qual todas as interações do chat são construídas.

## What Changes

- Converter a home (`/`) de Controller estático para **LiveView de onboarding**: campo de nome com preview de avatar em tempo real via `phx-change`, botões "Explorar salas" e "Criar sala"
- Ao submeter o formulário, persistir a guest session diretamente no LiveView via `Phoenix.LiveView.put_session/3` e redirecionar — sem controller intermediário
- **Sessão mínima**: apenas `{session_id: UUID, name: string}` armazenados no cookie; avatar é sempre *computado* do `name` no momento da renderização, nunca armazenado
- **Avatar via CSS + iniciais**: extrair até 2 iniciais do nome, atribuir cor de fundo determinística usando `Enum.at(colors, :erlang.phash2(name, length(colors)))` com as cores DaisyUI do design system — zero dependências externas, zero requests
- Se `current_user` autenticado estiver presente (AshAuthentication), usar o email como nome de exibição e Gravatar como avatar — esta é a única diferença de display do upgrade path no Change 1; nenhum merge de dados ocorre ainda
- **Guard com `return_to`**: ao tentar acessar `/rooms` ou `/rooms/new` sem nome na sessão, redirecionar para `/?return_to=<destino>` para não perder o destino original após o onboarding
- Se o usuário já tem nome na sessão e navega para `/`, redirecionar direto para `/rooms`

## Decisions

- **Home é LiveView** (não Controller): consistente com o padrão da app; `put_session/3` do LiveView 1.0+ elimina a necessidade de controller intermediário
- **Avatar sem armazenamento**: computar iniciais + cor do `name` a cada render evita sincronização de estado; mudar o nome muda o avatar automaticamente
- **Upgrade path no Change 1 = apenas display**: a vinculação real entre `session_id` e `User` (para atribuição de mensagens históricas) fica para após o Change 3 quando mensagens existirem no banco
- **Guard com `return_to`**: essencial para o caso de receber um link de sala diretamente; sem isso a UX de convite quebra

## Capabilities

### New Capabilities

- `guest-identity`: Identidade de sessão para participantes — estrutura `{session_id, name}` no cookie, geração de avatar por iniciais com cor determinística, display upgrade para usuário autenticado, guard com redirecionamento preservando destino

### Modified Capabilities

*(nenhuma — sem specs existentes)*

## Impact

- `lib/lets_chat_web/live/home_live.ex` — novo LiveView substitui o PageController na rota `/`
- `lib/lets_chat_web/router.ex` — trocar `get "/"` por `live "/"` dentro do `ash_authentication_live_session`; adicionar guard de sessão como `on_mount`
- `lib/lets_chat_web/live_user_auth.ex` — adicionar `on_mount :require_guest_name` para guard com `return_to`
- `lib/lets_chat_web/components/core_components.ex` — novo componente `<.avatar>` (iniciais + cor DaisyUI)
- `lib/lets_chat_web/controllers/page_controller.ex` — pode ser removido se não houver outras rotas dependentes
- Sem migrações — guest session é 100% baseada em cookie de sessão Phoenix
