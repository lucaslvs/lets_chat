## Context

A aplicação usa Phoenix + Tailwind CSS v4 + daisyUI v4. O design system Kraken está documentado em `.agents/docs/design-system.md` mas não está refletido em nenhuma parte do código — as cores são Phoenix-orange (padrão do scaffold), as fontes são do sistema, e os componentes ignoram os tokens Kraken.

O daisyUI v4 usa CSS custom properties (`--color-primary`, `--color-base-100`, etc.) que são consumidas por suas classes utilitárias. Isso nos dá um ponto de entrada limpo: ao atualizar essas variáveis no tema, todos os componentes daisyUI herdam as cores automaticamente sem tocar nos templates.

## Goals / Non-Goals

**Goals:**
- Mapear tokens Kraken para variáveis do tema daisyUI (`app.css`)
- Configurar tipografia com fallbacks imediatos (IBM Plex Sans / Helvetica Neue) e estrutura pronta para fontes reais
- Atualizar `<.button>` e `<.header>` em `core_components.ex` com classes Kraken explícitas
- Restyle de `home.html.heex` — remover scaffold Phoenix, aplicar Kraken
- Criar versão dark Kraken no tema `dark`

**Non-Goals:**
- Construir novas telas ou componentes além dos existentes
- Criar um sistema de tema configurável pelo usuário
- Modificar lógica de negócio ou dados

## Decisions

### D1 — Abordagem híbrida: token mapping + classes diretas

**Decisão:** Atualizar variáveis do tema daisyUI para valores Kraken, e usar classes Tailwind diretas (`bg-[#7132f5]`, `text-[#101114]`) onde o daisyUI não cobre exatamente o spec.

**Alternativas consideradas:**
- *Só classes diretas*: 100% fiel ao spec mas perde a DX do daisyUI e exige reescrever todo o HTML existente
- *Só token mapping*: daisyUI controla o radius, padding, e outros detalhes que podem não bater exato com o Kraken spec

**Rationale:** O design system é explicitamente "additive" (AGENTS.md: "daisyUI coexists — apply Kraken tokens for all new components"). O token mapping garante herança automática; classes diretas cobrem os detalhes finos.

---

### D2 — Formato de cor no tema daisyUI: hex direto

**Decisão:** Usar hex values (`#7132f5`) nas variáveis do tema, não converter para oklch.

**Alternativas consideradas:**
- *Converter para oklch*: necessário se daisyUI precisar computar variantes de cor. Mas daisyUI v4 + Tailwind v4 usam as variáveis CSS diretamente como valores de cor, sem manipulação em runtime.

**Rationale:** Hex é a fonte de verdade do design system. Converter para oklch introduz erro de arredondamento e dificulta manutenção. CSS aceita hex como valor de custom property sem problemas.

---

### D3 — Fontes: Google Fonts como placeholder

**Decisão:** Carregar IBM Plex Sans (Google Fonts) via `<link>` no `root.html.heex`. Declarar `font-family: 'Kraken-Brand', 'IBM Plex Sans', Helvetica, Arial` no CSS. Quando os arquivos `.woff2` chegarem, adicionar `@font-face` apontando para eles — o resto do código não muda.

**Rationale:** IBM Plex Sans é geometricamente próxima do estilo Kraken-Brand (humanist sans-serif, bold weights bem definidos). A estrutura de fallback do design system já prevê isso. Usar Google Fonts evita bloquear a implementação enquanto os arquivos reais não estão disponíveis.

---

### D4 — Dark mode: Kraken navy

**Decisão:** Criar versão dark com superfícies navy (`#13131f`, `#1a1a2e`, `#25253a`), roxo clarificado para primary (`#9b72fb`), e texto próximo ao branco (`#e8e9f0`).

**Alternativas consideradas:**
- *Desabilitar dark mode*: mais simples, mas o toggle já existe no app e o usuário decidiu manter
- *Manter cores Phoenix no dark*: inconsistente com a identidade Kraken

**Rationale:** O hue do roxo Kraken (`291°`) é mantido no dark — só o lightness é aumentado para garantir contraste adequado sobre fundo escuro.

---

### D5 — `<.button>` no `core_components.ex`

**Decisão:** Substituir as classes daisyUI `btn btn-primary` / `btn-primary btn-soft` por classes Kraken diretas. Manter a API do componente (`variant="primary"`, `variant="outlined"`, etc.) inalterada.

**Rationale:** O `btn` do daisyUI tem padding e radius próprios que não correspondem exatamente ao spec Kraken (`py-[13px]`, `rounded-xl`). Como já estamos no `core_components.ex`, faz sentido ser explícito aqui.

---

### D6 — Auth pages: herança via tema, sem AuthOverrides

**Decisão:** Não adicionar overrides em `AuthOverrides` nesta mudança. Verificar após aplicar o tema se as páginas de auth ficam visualmente coerentes.

**Rationale:** As páginas de auth usam `AshAuthentication.Phoenix.Overrides.DaisyUI`, que consome as variáveis do tema. Com o tema atualizado, as cores primárias, botões e inputs devem herdar o Kraken automaticamente. AuthOverrides pode ser adicionado em uma mudança futura se necessário.

## Risks / Trade-offs

- **Hex vs oklch**: Se versões futuras do daisyUI exigirem oklch para computar variantes (ex: `btn-primary:hover` com lightness relativo), os hex values podem não funcionar. Mitigação: monitorar changelog do daisyUI; a conversão é mecânica se necessário.

- **IBM Plex Sans via CDN**: Adiciona uma dependência externa e uma requisição de rede. Mitigação: Google Fonts usa `font-display: swap` por padrão, sem impacto no LCP. Quando as fontes reais chegarem, a dependência some.

- **home.html.heex é scaffold**: O restyle vai transformar a página padrão Phoenix em algo alinhado ao Kraken, mas sem conteúdo real de produto. Aceitável como estado transitório.

## Migration Plan

1. Atualizar `assets/css/app.css` — temas light e dark
2. Adicionar `<link>` do Google Fonts no `root.html.heex`
3. Atualizar `core_components.ex` — button e header
4. Restyle `home.html.heex`
5. Rodar `mix precommit` e verificar visualmente no browser

Rollback: as mudanças são todas no frontend (CSS + templates), sem migração de banco. Reverter via git é imediato.

## Open Questions

- **(Resolvida)** Manter dark mode? → Sim, com palette Kraken navy
- **(Resolvida)** Estratégia de componentes? → Híbrido (token mapping + classes diretas)
- Quando os arquivos Kraken-Brand/Product ficarem disponíveis, qual será a forma de distribuição? (self-hosted woff2 vs CDN privado)
