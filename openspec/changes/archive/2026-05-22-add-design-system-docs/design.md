## Context

O projeto usa `usage_rules` para gerenciar skills e contexto de IA via deps. O spec `agent-context-config` define como esse sistema funciona. Até agora, não havia um lugar definido para arquivos de contexto de IA que **não** são gerenciados pelo `usage_rules` — como design system, decisões de produto, guias visuais. O `DESIGN.md` existia na raiz como documento humano sem nenhum mecanismo de injeção para o agente.

## Goals / Non-Goals

**Goals:**
- Estabelecer `.agents/docs/` como namespace canônico para contexto de IA não-usage_rules
- Garantir que o agente receba contexto do design system automaticamente ao tocar arquivos do web layer
- Manter o documento lean e agent-optimized (não uma cópia do doc humano)

**Non-Goals:**
- Substituir ou modificar o sistema `usage_rules`
- Criar um sistema de design completo com tokens CSS/Tailwind configurados
- Cobrir contexto de design para outros diretórios além do web layer neste momento

## Decisions

### Progressive disclosure via subdirectório AGENTS.md

**Decisão**: Criar `lib/lets_chat_web/AGENTS.md` como mecanismo de injeção, com regras críticas inline.

**Alternativas consideradas**:
- *Root AGENTS.md*: Carrega sempre, mas aumenta contexto global para todos os agentes, não só os que tocam UI.
- *Skill customizada*: Requer invocação explícita pelo usuário, não é automático.
- *Modificar `phoenix-framework/SKILL.md`*: O arquivo tem `managed-by: usage-rules` — mudanças seriam sobrescritas no próximo `mix usage_rules.sync`.

**Rationale**: Subdirectório AGENTS.md é o mecanismo correto para progressive disclosure — é automaticamente carregado pelo Claude Code quando o agente opera em arquivos daquela árvore de diretórios, sem custo nos outros contextos.

### Regras críticas inline + referência ao doc completo

**Decisão**: `lib/lets_chat_web/AGENTS.md` contém as regras mais usadas inline (cores, tipografia, botões) e aponta para `.agents/docs/design-system.md` para detalhes.

**Rationale**: Claude Code não segue referências a arquivos externos automaticamente. Inline garante que o agente sempre tenha o essencial; a referência permite busca sob demanda.

### `.agents/docs/` como namespace separado de `.agents/skills/`

**Decisão**: Criar `docs/` como subdiretório de `.agents/`, separado de `commands/` e `skills/`.

**Rationale**: `skills/` contém arquivos gerenciados pelo `usage_rules` (têm frontmatter `managed-by`). `docs/` é para arquivos de contexto projeto-específicos que o time gerencia diretamente, sem risco de sobrescrita.

## Risks / Trade-offs

- **Subdirectório AGENTS.md pode ser ignorado** por agentes que não implementam a spec → Mitigação: as regras mais críticas ficam inline, não dependem de follow-up.
- **Desync entre `lib/lets_chat_web/AGENTS.md` e `.agents/docs/design-system.md`** se o design system evoluir → Mitigação: o workflow correto é atualizar ambos via OpenSpec change.
- **daisyUI coexistindo com design system** pode criar ambiguidade → Mitigação: o doc deixa explícito que o design system é aditivo, não substitutivo.
