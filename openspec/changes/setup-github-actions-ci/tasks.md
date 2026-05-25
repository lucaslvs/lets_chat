## 1. Dependências de Qualidade

- [x] 1.1 Adicionar `credo` ao `mix.exs` em `[:dev, :test]`
- [x] 1.2 Adicionar `sobelow` ao `mix.exs` em `[:dev, :test]` (necessário pois CI usa `MIX_ENV=test`)
- [x] 1.3 Adicionar `dialyxir` ao `mix.exs` em `[:dev]`
- [x] 1.4 Adicionar `mix_audit` ao `mix.exs` em `[:dev]`
- [x] 1.5 Rodar `mix deps.get` e verificar que todas as deps resolvem sem conflito

## 2. Gerenciamento de Versões com mise

- [x] 2.1 Criar `.mise.toml` na raiz com `erlang = "27.3"`, `elixir = "1.18.3-otp-27"`, `node = "22.14.0"`
- [x] 2.2 Adicionar seção `[env]` com `KERL_CONFIGURE_OPTIONS`, `KERL_BUILD_DOCS` e `ERL_AFLAGS`
- [x] 2.3 Adicionar seção `[tasks]` com tasks: `setup`, `server`, `test`, `precommit`
- [x] 2.4 Adicionar `[hooks] postinstall = "mix deps.get"`
- [x] 2.5 Verificar que `mise run precommit` executa corretamente

## 3. Workflow GitHub Actions

- [x] 3.1 Criar diretório `.github/workflows/`
- [x] 3.2 Criar `.github/workflows/elixir.yml` com trigger em `push` e `pull_request` para `main`
- [x] 3.3 Configurar serviço PostgreSQL 16 com health check no job
- [x] 3.4 Adicionar step `jdx/mise-action@v2` com `cache: true` para instalar Erlang e Elixir
- [x] 3.5 Adicionar step de cache para `deps/` e `_build/` keyed em `mix.lock`
- [x] 3.6 Adicionar step de cache separado para o PLT do Dialyzer (`priv/plts/`) keyed em `mix.lock`
- [x] 3.7 Adicionar step de cache bust condicional (`if: github.run_attempt != '1'`)
- [x] 3.8 Adicionar steps em sequência: `mix deps.get`, `mix compile --warnings-as-errors`
- [x] 3.9 Adicionar steps: `mix format --check-formatted`, `mix deps.unlock --check-unused`
- [x] 3.10 Adicionar steps: `mix hex.audit`, `mix deps.audit`
- [x] 3.11 Adicionar steps: `mix credo --strict`, `mix sobelow --skip`
- [x] 3.12 Adicionar step `mix dialyzer` com variáveis de env CI apropriadas (`KERL_BUILD_DOCS: "no"`, `MISE_YES: "1"`)
- [x] 3.13 Adicionar step final `mix test`

## 4. Verificação

- [x] 4.1 Rodar `mix precommit` localmente e confirmar que todos os checks passam
- [ ] 4.2 Fazer push para um branch de teste e verificar que o workflow é disparado no GitHub Actions
- [ ] 4.3 Confirmar que todos os steps do CI passam no primeiro run (exceto potencial lentidão do cold start)
- [ ] 4.4 Confirmar que o segundo run é significativamente mais rápido (cache hit para deps, _build e PLT)
