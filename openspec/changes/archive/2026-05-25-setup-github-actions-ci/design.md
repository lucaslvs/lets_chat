## Context

O projeto `lets_chat` (Phoenix 1.8 + Ash 3.0 + AshPostgres + live_vue) não possui nenhuma configuração de CI. Erros de compilação, formatação e falhas de teste dependem de verificação manual. Não há gerenciamento de versões de runtime (Elixir/OTP/Node), criando risco de divergência entre ambientes.

**Investigação realizada:**
- Os testes não requerem assets compilados: `live_vue` em test env usa `ssr_module: nil`, retornando HTML vazio sem invocar Vite ou Node.js
- Nenhum arquivo de versão existe (`.tool-versions`, `.nvmrc`, etc.)
- O `mix precommit` alias já cobre os checks fundamentais: compile, deps.unlock, format, test

## Goals / Non-Goals

**Goals:**
- Pipeline de CI automatizado no GitHub Actions para cada push e PR
- Gerenciamento de versões com mise como fonte única de verdade (local + CI)
- Cobertura completa: compile, format, deps checks, security, quality, type checking e tests
- Caches otimizados para minimizar tempo de execução em runs subsequentes
- Cache bust automático em retries sem intervenção manual

**Non-Goals:**
- CD (deploy automatizado) — fora do escopo desta mudança
- Build de assets no CI — não necessário para os testes atuais
- Matrix de versões (múltiplas combinações Elixir/OTP) — projeto pinna versões exatas
- Cobertura de código (`--cover`) — pode ser adicionada em mudança futura

## Decisions

### D1: mise via `jdx/mise-action@v2` em vez de `erlef/setup-beam`

**Escolha:** `jdx/mise-action@v2` lendo `.mise.toml`

**Rationale:** `.mise.toml` é a fonte única de verdade para versões — usado tanto localmente quanto no CI. Com `erlef/setup-beam`, as versões ficam duplicadas (`.mise.toml` local + YAML do workflow), criando risco de drift.

**Alternativa considerada:** `erlef/setup-beam` com versões inline no YAML — descartado por criar duplicação.

**Trade-off:** Cold start mais lento (Erlang compila de source em ~10–15 min na primeira vez) versus eliminação total de drift de versão. Mitigado por `cache: true` na action.

---

### D2: Job único em vez de jobs paralelos

**Escolha:** Um único job sequencial

**Rationale:** Jobs paralelos (ex: `test` + `quality` em paralelo) reduzem tempo de wall-clock mas aumentam complexidade de manutenção e custo de minutos de CI. Para o tamanho e estágio atual do projeto, job único é mais simples e ainda dá feedback completo em ~5–7 min (com cache quente).

**Alternativa considerada:** Jobs paralelos — reservado para quando o CI ultrapassar 10 min regularmente.

---

### D3: Sem Node.js/Vite no CI

**Escolha:** Não instalar Node.js nem rodar Vite build no CI

**Rationale:** Investigação confirmou que `live_vue` em test env tem `ssr_module: nil`. `LiveVue.SSR.render/3` retorna `%{preloadLinks: "", html: ""}` sem tocar em nenhum arquivo JS. Nenhum teste existente depende de assets compilados.

**Riscos:** Se futuramente forem adicionados testes para `VueDemoLive` ou outros componentes Vue com SSR, o CI precisará de Node.js. Documentar como nota no workflow.

---

### D4: Ferramentas de qualidade selecionadas

| Ferramenta | Check | Dep adicionada |
|---|---|---|
| Styler/mix format | `mix format --check-formatted` | já existe |
| Credo | `mix credo --strict` | `credo` |
| Sobelow | `mix sobelow --skip` | `sobelow` |
| Dialyxir | `mix dialyzer` | `dialyxir` |
| mix_audit | `mix deps.audit` | `mix_audit` |
| Hex | `mix hex.audit` | já existe (hex) |

`--skip` no Sobelow pula checks que requerem arquivos não presentes (evita falsos positivos em projetos sem certas features). `--strict` no Credo ativa todas as categorias de checks.

---

### D5: Estratégia de cache do Dialyzer

Dialyzer requer uma PLT (Persistent Lookup Table) que leva ~5–10 min para construir. O PLT deve ser cacheado **separadamente** do `_build` porque:
1. Muda quando as dependências OTP mudam (não só o `mix.lock`)
2. É específico por versão de OTP

**Cache key:** `${{ runner.os }}-dialyzer-${{ hashFiles('**/mix.lock') }}`  
**Path:** `priv/plts/` (convenção do dialyxir)

---

### D6: Ordem dos steps no CI

Steps ordenados do mais rápido/simples para o mais lento/custoso para dar feedback rápido em falhas comuns:

```
compile → format → deps checks → hex/deps audit → credo → sobelow → dialyzer → test
```

Falhas de compile bloqueiam todos os outros; format e deps checks são rápidos e pegam erros triviais cedo.

## Risks / Trade-offs

- **[Cold start lento]** → Mitigado por `cache: true` na mise-action e caches separados para deps, _build e PLT. Primeira execução será lenta; subsequentes são rápidas.
- **[PLT stale]** → Se houver mudanças incompatíveis no OTP sem atualizar o mix.lock, o PLT pode ficar stale. Mitigado incluindo `otp-version` na cache key (via mise).
- **[Dialyzer em projetos Ash]** → Ash usa muita metaprogramação. Dialyzer pode gerar falsos positivos. `dialyxir` por padrão usa `ignore_warnings:` — pode ser necessário criar `.dialyzer_ignore.exs` ao longo do tempo.
- **[Assets em testes futuros]** → Se forem adicionados testes de integração com SSR, o CI precisará de step de Node.js + Vite. Mitigado documentando explicitamente no workflow.
