## 1. Configurar usage_rules no mix.exs

- [x] 1.1 Adicionar a função `usage_rules/0` ao `mix.exs` com `file: "AGENTS.md"`, `usage_rules: ["usage_rules:all"]`, e os 3 skills compostos (ash-framework, live-vue, phoenix-framework)
- [x] 1.2 Adicionar a chave `usage_rules: usage_rules()` dentro de `project/0` no `mix.exs`

## 2. Gerar skills via usage_rules.sync

- [x] 2.1 Executar `mix usage_rules.sync` e verificar que os 3 skills foram criados em `.agents/skills/`
- [x] 2.2 Verificar que `.agents/skills/ash-framework/SKILL.md` existe e contém conteúdo das regras Ash
- [x] 2.3 Verificar que `.agents/skills/live-vue/SKILL.md` existe e contém conteúdo das regras LiveVue
- [x] 2.4 Verificar que `.agents/skills/phoenix-framework/SKILL.md` existe e contém regras de phoenix:all, elixir e otp

## 3. Reescrever AGENTS.md para conteúdo mínimo

- [x] 3.1 Substituir o conteúdo do AGENTS.md pelo conteúdo mínimo: descrição do projeto, `mix precommit`, regra Req, e o conteúdo gerado de `usage_rules:all`
- [x] 3.2 Verificar que o AGENTS.md resultante tem no máximo 60 linhas

## 4. Adicionar conteúdo custom ao skill phoenix-framework

- [x] 4.1 Inserir acima do marcador `<!-- usage-rules:start -->` no `.agents/skills/phoenix-framework/SKILL.md` as regras Phoenix v1.8 específicas do projeto: wrapping com `<Layouts.app flash={@flash}>`, padrão `current_scope`, proibição de `<.flash_group>` fora de layouts, uso de `<.icon>` e `<.input>`
- [x] 4.2 Inserir as regras JS/CSS: Tailwind v4 import syntax, sem `@apply`, sem daisyUI, apenas `app.js` e `app.css`, sem inline `<script>` tags
- [x] 4.3 Inserir UI/UX design principles: world-class UI, micro-interactions, clean typography, hover effects
- [x] 4.4 Inserir Mix guidelines do projeto e Test guidelines (LiveView test patterns)

## 5. Verificação final

- [x] 5.1 Executar `mix usage_rules.sync` novamente e confirmar que o conteúdo custom do skill `phoenix-framework` é preservado (idempotência)
- [x] 5.2 Confirmar que `CLAUDE.md` ainda está apontando para `AGENTS.md` via symlink
