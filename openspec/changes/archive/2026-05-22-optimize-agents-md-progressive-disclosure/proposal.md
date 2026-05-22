## Why

O `AGENTS.md` atual tem 881 linhas carregadas em toda request do agente — ~800 delas são regras de domínio (Phoenix, Ash, LiveVue) que já existem nos próprios deps como `usage-rules.md`, mas estão duplicadas inline. Isso desperdiça o budget de tokens (~150-200 instruções seguidas com consistência) e dilui a atenção do agente em contextos onde essas regras não são relevantes.

## What Changes

- Configurar `usage_rules` no `mix.exs` com 3 skills compostas (ash-framework, live-vue, phoenix-framework)
- Executar `mix usage_rules.sync` para gerar os skills e limpar o AGENTS.md
- Reescrever o AGENTS.md para conter apenas conteúdo essencial e genuinamente projeto-específico (~30 linhas)
- Adicionar conteúdo custom ao skill `phoenix-framework` com as regras Phoenix v1.8 e JS/CSS específicas deste projeto

## Capabilities

### New Capabilities

- `agent-context-config`: Configuração declarativa de contexto de agente via `usage_rules` no `mix.exs`, com progressive disclosure através de skills por domínio (ash-framework, live-vue, phoenix-framework)

### Modified Capabilities

<!-- nenhuma spec existente precisa ser alterada -->

## Impact

- `mix.exs`: adição da função `usage_rules/0` e chave `usage_rules:` em `project/0`
- `AGENTS.md`: redução de 881 para ~30 linhas (remoção do conteúdo duplicado de deps)
- `.agents/skills/`: criação de 3 novos skills gerenciados pelo usage_rules
- Nenhuma mudança em código de aplicação, testes ou banco de dados
