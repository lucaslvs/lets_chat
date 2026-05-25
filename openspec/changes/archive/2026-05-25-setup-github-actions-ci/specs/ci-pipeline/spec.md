## ADDED Requirements

### Requirement: CI executa em push e pull request para main
O sistema SHALL executar o pipeline de CI automaticamente em pushes para `main` e em PRs que têm `main` como base.

#### Scenario: Push para main dispara CI
- **WHEN** um commit é pushed para o branch `main`
- **THEN** o workflow `Elixir CI` é disparado no GitHub Actions

#### Scenario: PR com base em main dispara CI
- **WHEN** um pull request é aberto ou atualizado com base no branch `main`
- **THEN** o workflow `Elixir CI` é disparado e seus checks aparecem no PR

---

### Requirement: CI compila o projeto sem warnings
O sistema SHALL falhar se `mix compile --warnings-as-errors` retornar qualquer warning ou erro.

#### Scenario: Compilação com warnings falha o CI
- **WHEN** o código contém um warning de compilação (ex: variável não usada)
- **THEN** o step "Compile" falha e o pipeline para

#### Scenario: Compilação limpa passa o step
- **WHEN** o código compila sem warnings nem erros
- **THEN** o step "Compile" é concluído com sucesso

---

### Requirement: CI verifica formatação do código
O sistema SHALL falhar se `mix format --check-formatted` detectar código não formatado.

#### Scenario: Código não formatado falha o CI
- **WHEN** um arquivo foi modificado sem rodar `mix format`
- **THEN** o step "Check Formatting" falha listando os arquivos afetados

#### Scenario: Código formatado passa o step
- **WHEN** todos os arquivos estão formatados conforme `mix format`
- **THEN** o step "Check Formatting" é concluído com sucesso

---

### Requirement: CI verifica dependências não utilizadas
O sistema SHALL falhar se `mix deps.unlock --check-unused` detectar dependências removidas mas ainda presentes no `mix.lock`.

#### Scenario: mix.lock com deps não usadas falha o CI
- **WHEN** uma dependência foi removida do `mix.exs` mas o `mix.lock` não foi atualizado
- **THEN** o step "Check Unused Deps" falha

#### Scenario: mix.lock sincronizado passa o step
- **WHEN** o `mix.lock` reflete exatamente as dependências declaradas
- **THEN** o step "Check Unused Deps" é concluído com sucesso

---

### Requirement: CI audita pacotes Hex retired
O sistema SHALL falhar se `mix hex.audit` encontrar dependências marcadas como retired pelos seus mantenedores.

#### Scenario: Dep retired detectada
- **WHEN** uma dependência foi marcada como retired no Hex.pm
- **THEN** o step "Hex Audit" falha listando os pacotes afetados

---

### Requirement: CI audita vulnerabilidades em dependências
O sistema SHALL executar `mix deps.audit` para verificar vulnerabilidades conhecidas no banco de dados de segurança do Elixir.

#### Scenario: Vulnerabilidade conhecida detectada
- **WHEN** uma dependência tem uma vulnerabilidade no banco de dados de segurança
- **THEN** o step "Deps Security Audit" falha com detalhes da vulnerabilidade

---

### Requirement: CI executa análise de qualidade com Credo
O sistema SHALL executar `mix credo --strict` e falhar se houver violações.

#### Scenario: Violação de estilo detectada
- **WHEN** o código viola regras de Credo em modo strict
- **THEN** o step "Credo" falha listando as violações com localização

---

### Requirement: CI executa análise de segurança com Sobelow
O sistema SHALL executar `mix sobelow --skip` e falhar se vulnerabilidades de segurança forem encontradas.

#### Scenario: Vulnerabilidade de segurança detectada
- **WHEN** o código contém um padrão de vulnerabilidade reconhecido pelo Sobelow
- **THEN** o step "Sobelow Security Analysis" falha com detalhes

---

### Requirement: CI executa type checking com Dialyzer
O sistema SHALL executar `mix dialyzer` e falhar se erros de tipo forem encontrados.

#### Scenario: Erro de tipo detectado
- **WHEN** o código contém inconsistências de tipo detectáveis pelo Dialyzer
- **THEN** o step "Dialyzer" falha listando as discrepâncias

#### Scenario: PLT é reutilizado entre runs
- **WHEN** o `mix.lock` não mudou desde o último run
- **THEN** o PLT é restaurado do cache e o step "Dialyzer" não reconstrói o PLT do zero

---

### Requirement: CI executa a suite de testes
O sistema SHALL executar `mix test` com PostgreSQL disponível e falhar se qualquer teste falhar.

#### Scenario: Teste falhando bloqueia o CI
- **WHEN** um ou mais testes falham
- **THEN** o step "Run Tests" falha com output dos testes que falharam

#### Scenario: Todos os testes passando conclui o CI
- **WHEN** todos os testes passam
- **THEN** o step "Run Tests" e o workflow completo são marcados como sucesso

---

### Requirement: CI usa cache para deps e build artifacts
O sistema SHALL cachear `deps/` e `_build/` separadamente, keyed pelo hash do `mix.lock`, e restaurar esses caches no início de cada run.

#### Scenario: Cache hit acelera o run
- **WHEN** o `mix.lock` não mudou desde o último run
- **THEN** `mix deps.get` e `mix compile` completam significativamente mais rápido

#### Scenario: Cache bust em retry
- **WHEN** `github.run_attempt` é diferente de `'1'` (run sendo retentado)
- **THEN** `mix deps.clean --all` e `mix clean` são executados antes de reinstalar deps

---

### Requirement: CI requer PostgreSQL disponível para os testes
O sistema SHALL iniciar um serviço PostgreSQL 16 como parte do job, configurado com usuário e senha `postgres`.

#### Scenario: Serviço PostgreSQL disponível
- **WHEN** o job inicia
- **THEN** um container PostgreSQL 16 está disponível em `localhost:5432` com health check passando antes dos steps iniciarem
