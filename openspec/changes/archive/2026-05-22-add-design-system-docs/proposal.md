## Why

O agente não tinha mecanismo para acessar o design system do projeto ao trabalhar em arquivos de UI — o contexto existia apenas como `DESIGN.md` na raiz, sem nenhuma forma de injeção automática. Com o crescimento da interface, isso gera inconsistência visual entre componentes gerados por IA.

## What Changes

- Novo diretório `.agents/docs/` como namespace para arquivos de contexto de IA que não são gerenciados pelo `usage_rules`
- `.agents/docs/design-system.md` — spec condensada e agent-optimized do Kraken-inspired design system (cores, tipografia, botões, badges, shadows, do/don'ts)
- `lib/lets_chat_web/AGENTS.md` — trigger de progressive disclosure: carregado automaticamente quando o agente toca qualquer arquivo do web layer, com regras críticas inline + referência ao doc completo
- `DESIGN.md` removido da raiz (substituído pelo doc em `.agents/docs/`)

## Capabilities

### New Capabilities
- `agent-design-context`: Como o contexto do design system é organizado em `.agents/docs/` e injetado progressivamente via subdirectório `AGENTS.md` no web layer

### Modified Capabilities

## Impact

- `.agents/docs/design-system.md` — arquivo novo
- `lib/lets_chat_web/AGENTS.md` — arquivo novo
- `DESIGN.md` — removido da raiz
