## Purpose

Defines how agent context configuration is structured in the project — specifically, how `usage_rules` is configured in `mix.exs` to generate skill files for AI agents, and what content belongs in `AGENTS.md` vs. in the generated skill files.

## Requirements

### Requirement: usage_rules configurado no mix.exs
O `mix.exs` SHALL conter uma função `usage_rules/0` referenciada pela chave `usage_rules:` em `project/0`, com `file: "AGENTS.md"`, `usage_rules: [{:usage_rules, [sub_rules: []]}]` (apenas o arquivo principal do dep `usage_rules`, sem sub-regras como `elixir.md`/`otp.md`), e 3 skills compostos definidos em `skills: [build: [...]]`.

#### Scenario: Configuração presente e funcional
- **WHEN** o desenvolvedor executa `mix usage_rules.sync`
- **THEN** o comando completa sem erros e gera os 3 skills em `.agents/skills/`

#### Scenario: Skill ash-framework gerado
- **WHEN** `mix usage_rules.sync` é executado
- **THEN** o arquivo `.agents/skills/ash-framework/SKILL.md` existe e contém regras de `:ash`, `ash:all`, `:ash_postgres`, `ash_postgres:all`, `:ash_authentication`, `:ash_phoenix`, `ash_phoenix:all`, `:spark`, `:reactor`, `:igniter`

#### Scenario: Skill live-vue gerado
- **WHEN** `mix usage_rules.sync` é executado
- **THEN** o arquivo `.agents/skills/live-vue/SKILL.md` existe e contém as regras de `:live_vue`

#### Scenario: Skill phoenix-framework gerado
- **WHEN** `mix usage_rules.sync` é executado
- **THEN** o arquivo `.agents/skills/phoenix-framework/SKILL.md` existe e contém regras de `phoenix:all`, `:elixir`, `:otp`

### Requirement: AGENTS.md mínimo e projeto-específico
O `AGENTS.md` SHALL conter apenas: descrição do projeto em 1 linha, comandos essenciais (`mix precommit`), regra de HTTP client (Req), e o conteúdo gerado pelo dep `usage_rules` (meta-regras de `search_docs`/`docs`). Não SHALL conter regras inline de Phoenix, LiveView, HEEx, LiveVue, Ash ou OTP.

#### Scenario: AGENTS.md com menos de 60 linhas
- **WHEN** a otimização é aplicada
- **THEN** `AGENTS.md` tem no máximo 60 linhas

#### Scenario: Sem conteúdo duplicado de deps
- **WHEN** o AGENTS.md final é comparado com deps/live_vue/usage-rules.md
- **THEN** não há blocos de texto idênticos entre os dois arquivos

### Requirement: Conteúdo custom Phoenix v1.8 preservado no skill
O skill `phoenix-framework` SHALL conter, acima dos marcadores `<!-- usage-rules:start -->`, as regras projeto-específicas: wrapping com `<Layouts.app>`, padrão `current_scope`, proibição de `<.flash_group>` fora de layouts, uso de `<.icon>` e `<.input>`, Tailwind v4 import syntax, regras JS/CSS (sem @apply, sem daisyUI, sem inline scripts), e UI/UX design principles.

#### Scenario: Regras v1.8 presentes no skill
- **WHEN** o arquivo `.agents/skills/phoenix-framework/SKILL.md` é lido
- **THEN** contém a instrução sobre `<Layouts.app flash={@flash}>` acima do marcador `<!-- usage-rules:start -->`

#### Scenario: Conteúdo custom preservado após resync
- **WHEN** `mix usage_rules.sync` é executado novamente após adicionar conteúdo custom
- **THEN** o conteúdo custom acima do marcador `<!-- usage-rules:start -->` é preservado intacto

### Requirement: Sync idempotente
O comando `mix usage_rules.sync` SHALL ser idempotente — executar múltiplas vezes SHALL produzir o mesmo resultado sem erros ou duplicação de conteúdo.

#### Scenario: Segunda execução não duplica conteúdo
- **WHEN** `mix usage_rules.sync` é executado duas vezes consecutivas
- **THEN** os arquivos resultantes são idênticos à primeira execução
