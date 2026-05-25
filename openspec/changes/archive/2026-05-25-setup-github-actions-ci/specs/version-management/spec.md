## ADDED Requirements

### Requirement: Versões de runtime declaradas em .mise.toml
O sistema SHALL ter um arquivo `.mise.toml` na raiz do projeto declarando versões exatas de Erlang, Elixir e Node.js.

#### Scenario: Versões são ativadas ao entrar no diretório
- **WHEN** um desenvolvedor executa `cd lets_chat` com `mise activate` configurado no shell
- **THEN** as versões declaradas no `.mise.toml` são ativadas automaticamente

#### Scenario: Versões instaladas com mise install
- **WHEN** um desenvolvedor executa `mise install` na raiz do projeto
- **THEN** Erlang 27.3, Elixir 1.18.3-otp-27 e Node.js 22.14.0 são instalados

---

### Requirement: .mise.toml é a fonte única de verdade para versões
O sistema SHALL usar `.mise.toml` tanto no desenvolvimento local quanto no CI, garantindo paridade de versões entre ambientes.

#### Scenario: CI usa as mesmas versões que o desenvolvimento local
- **WHEN** o CI executa via `jdx/mise-action@v2`
- **THEN** as versões lidas do `.mise.toml` do repositório são instaladas, sem duplicação no YAML do workflow

---

### Requirement: mise configura variáveis de ambiente do projeto
O arquivo `.mise.toml` SHALL declarar variáveis de ambiente ativadas ao entrar no diretório do projeto.

#### Scenario: ERL_AFLAGS ativado localmente
- **WHEN** um desenvolvedor entra no diretório do projeto
- **THEN** `ERL_AFLAGS="-kernel shell_history enabled"` está disponível no shell, habilitando histórico no IEx

#### Scenario: KERL_CONFIGURE_OPTIONS configurado para macOS
- **WHEN** mise instala Erlang em macOS com Homebrew
- **THEN** `KERL_CONFIGURE_OPTIONS` aponta para o OpenSSL do Homebrew, garantindo que crypto/ssl compile corretamente

---

### Requirement: mise expõe tasks para operações comuns do projeto
O arquivo `.mise.toml` SHALL declarar tasks executáveis via `mise run <task>` para as operações mais comuns.

#### Scenario: mise run setup inicializa o projeto
- **WHEN** um desenvolvedor executa `mise run setup`
- **THEN** `mix setup` é executado (instala deps, cria e migra o banco, compila assets)

#### Scenario: mise run server inicia o servidor de desenvolvimento
- **WHEN** um desenvolvedor executa `mise run server`
- **THEN** `mix phx.server` é executado

#### Scenario: mise run test executa os testes
- **WHEN** um desenvolvedor executa `mise run test`
- **THEN** `mix test` é executado

#### Scenario: mise run precommit executa checks antes de commit
- **WHEN** um desenvolvedor executa `mise run precommit`
- **THEN** `mix precommit` é executado (compile, deps.unlock, format, test)

---

### Requirement: mise instala deps Elixir automaticamente após mise install
O arquivo `.mise.toml` SHALL declarar um hook `postinstall` que executa `mix deps.get` após a instalação das ferramentas.

#### Scenario: deps são instaladas após mise install
- **WHEN** um desenvolvedor executa `mise install` pela primeira vez
- **THEN** `mix deps.get` é executado automaticamente ao final da instalação
