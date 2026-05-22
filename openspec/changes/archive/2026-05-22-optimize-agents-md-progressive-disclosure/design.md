## Context

O projeto usa `usage_rules ~> 1.0` como dep de dev mas sem nenhuma configuração em `mix.exs`. O `AGENTS.md` (881 linhas) foi gerado manualmente ou via comandos antigos — duplica conteúdo que já existe em `deps/live_vue/usage-rules.md` (502 linhas idênticas), `deps/phoenix/usage-rules/` (386 linhas em 5 sub-rules), e deps Ash (ash_authentication tem 377 linhas, ash tem 15 sub-rules, ash_postgres tem 8 sub-rules).

`CLAUDE.md` já é symlink para `AGENTS.md`. As skills existentes em `.agents/skills/` são do OpenSpec e não entram em conflito.

## Goals / Non-Goals

**Goals:**
- AGENTS.md com apenas conteúdo genuinamente projeto-específico (~30 linhas)
- 3 skills de domínio gerenciadas automaticamente por `mix usage_rules.sync`
- Conteúdo projeto-específico Phoenix v1.8 preservado no skill `phoenix-framework` como custom content (acima dos marcadores gerenciados)
- `mix usage_rules.sync` como source-of-truth para skills daqui em diante

**Non-Goals:**
- Mudanças em código de aplicação, schemas, testes ou banco de dados
- Criação de skills para deps que não têm usage-rules.md (ex: bandit, swoosh)
- Customização dos skills `ash-framework` e `live-vue` além do que os deps fornecem

## Decisions

### D1: 3 skills compostas em vez de 1 skill por dep

**Escolha:** 3 skills agrupadas por domínio de trabalho: `ash-framework`, `live-vue`, `phoenix-framework`.

**Alternativa considerada:** 1 skill por dep (use-ash, use-phoenix, use-live_vue...) via opção `deps:`.

**Rationale:** O agente escolhe skills por contexto de task, não por pacote. "Vou trabalhar em um formulário Ash Phoenix" → carrega `ash-framework`. Skills granulares por dep forçariam carregar múltiplos skills para uma task comum, anulando o benefício de progressive disclosure.

### D2: `usage_rules:all` inline no AGENTS.md (não como skill)

**Escolha:** Manter as instruções de `search_docs` e `docs` inline no AGENTS.md.

**Alternativa considerada:** Mover também para skill.

**Rationale:** Essas meta-regras ensinam O AGENTE A NAVEGAR DOCS de qualquer dep. São úteis em toda task independente de domínio — exatamente o critério do artigo para o que fica no AGENTS.md.

### D3: Conteúdo custom Phoenix v1.8 no topo do skill `phoenix-framework`

**Escolha:** Adicionar regras projeto-específicas (Layouts.app, current_scope, Tailwind v4, JS/CSS) como custom content acima dos marcadores `<!-- usage-rules:start -->` no skill gerado.

**Alternativa considerada:** Criar um arquivo separado `docs/PHOENIX_PROJECT.md` e linkar.

**Rationale:** O `usage_rules` preserva conteúdo acima dos marcadores gerenciados em cada `mix usage_rules.sync`. Manter tudo no mesmo skill arquivo evita fragmentação e garante que o agente receba regras do projeto junto com as regras do framework quando carregar o skill.

### D4: Incluir `:spark`, `:reactor`, `:igniter` no skill `ash-framework`

**Escolha:** Incluir spark, reactor e igniter no mesmo skill composto.

**Rationale:** Spark é a base do Ash DSL. Reactor é o engine de workflows do Ash. Igniter é o scaffolding tool do Ash. Um dev trabalhando com Ash inevitavelmente toca esses três — faz sentido carregar tudo junto.

## Risks / Trade-offs

- **Skills grandes**: O skill `ash-framework` será extenso (ash tem 15 sub-rules + ash_authentication tem 377 linhas). → Aceitável: só é carregado quando relevante, e o conteúdo é denso e útil para tasks Ash.
- **Regras Phoenix v1.8 fora do AGENTS.md**: O agente precisa lembrar de carregar o skill `phoenix-framework` para tarefas LiveView. → Mitigação: a `description` do skill é clara ("Use when working with Phoenix, LiveView, HEEx...") e os hooks do harness já instruem o agente a usar skills para tasks Elixir/Phoenix.
- **Drift do conteúdo custom**: As regras projeto-específicas no `phoenix-framework` podem divergir das regras do dep ao longo do tempo. → Aceitável: o conteúdo custom é exatamente o que é específico do projeto e não muda com versões do Phoenix.

## Migration Plan

1. Adicionar `usage_rules/0` no `mix.exs` e referenciar em `project/0`
2. Executar `mix usage_rules.sync` — isso limpa o AGENTS.md e gera os 3 skills
3. Reescrever o AGENTS.md manualmente para o conteúdo mínimo projeto-específico
4. Adicionar o bloco de conteúdo custom Phoenix v1.8 no topo do `.agents/skills/phoenix-framework/SKILL.md`
5. Verificar com `mix usage_rules.sync` novamente (deve ser idempotente)

**Rollback:** O AGENTS.md original pode ser restaurado via git. Os skills gerados podem ser deletados. A config no mix.exs pode ser removida.
