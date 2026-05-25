## Why

O projeto não tem nenhuma configuração de CI, o que significa que erros de compilação, formatação incorreta, vulnerabilidades em dependências e falhas de testes só são detectados manualmente. Estabelecer um pipeline automatizado garante qualidade consistente a cada PR e push, além de unificar o gerenciamento de versões entre ambientes local e CI via mise.

## What Changes

- Adicionar `.mise.toml` como fonte única de verdade para versões de Elixir, Erlang e Node.js
- Criar `.github/workflows/elixir.yml` com job único de CI cobrindo compile, format, quality e tests
- Adicionar dependências de qualidade ao `mix.exs`: `credo`, `sobelow`, `dialyxir`, `mix_audit`
- CI inclui cache agressivo para deps, `_build` e PLT do Dialyzer

## Capabilities

### New Capabilities

- `ci-pipeline`: Pipeline completo de CI no GitHub Actions com checks de compile, format, security, quality e testes — usando mise como gerenciador de versões com cache otimizado
- `version-management`: Configuração de mise (`.mise.toml`) para gerenciar Elixir, Erlang e Node.js localmente e no CI, com tasks, hooks e env vars de projeto

### Modified Capabilities

## Impact

- **Arquivos novos**: `.mise.toml`, `.github/workflows/elixir.yml`
- **`mix.exs`**: 4 novas dependências de dev (`credo`, `sobelow`, `dialyxir`, `mix_audit`)
- **Nenhuma mudança em código de aplicação** — impacto restrito a tooling e infraestrutura de CI
- **Primeira execução do CI**: lenta (~10–15 min) por compilação do Erlang e build do PLT; subsequentes são rápidas por cache
