## Why

A aplicação está usando as cores e tipografia padrão do scaffold Phoenix (laranja, fontes genéricas), sem refletir o design system Kraken estabelecido para o produto. Toda a interface precisa adotar os tokens visuais definidos antes de novas telas serem construídas.

## What Changes

- Atualizar os tokens do tema daisyUI `light` em `app.css` para as cores Kraken (roxo `#7132f5`, neutros, success)
- Criar versão dark Kraken adaptada no tema `dark` (superfícies navy + roxo clarificado para contraste)
- Configurar tipografia: IBM Plex Sans via Google Fonts como placeholder de `Kraken-Brand`; Helvetica Neue como placeholder de `Kraken-Product` — estrutura pronta para receber os arquivos reais quando disponíveis
- Atualizar `core_components.ex`: `<.button>` com padding/radius/cores Kraken; `<.header>` com tipografia Kraken-Brand
- Restyle de `home.html.heex`: remover SVG scaffold Phoenix, aplicar superfície branca, tipografia e botão CTA Kraken
- Verificar auth pages (sign in, register, reset): herança automática via tema + ajustes finos via `AuthOverrides` se necessário

## Capabilities

### New Capabilities

- `design-system-tokens`: Definição dos tokens visuais Kraken mapeados para variáveis daisyUI — cores (light + dark), tipografia, radius, sombras

### Modified Capabilities

*(nenhuma — sem specs existentes)*

## Impact

- `assets/css/app.css` — temas daisyUI light e dark
- `lib/lets_chat_web/components/core_components.ex` — button, header
- `lib/lets_chat_web/controllers/page_html/home.html.heex` — home page
- `lib/lets_chat_web/auth_overrides.ex` — possíveis ajustes nas auth pages
- `lib/lets_chat_web/components/layouts/root.html.heex` — importação de Google Fonts
- Sem mudanças em APIs, banco de dados ou lógica de negócio
