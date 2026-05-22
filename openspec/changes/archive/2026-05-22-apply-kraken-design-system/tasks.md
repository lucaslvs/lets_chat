## 1. Tema daisyUI — light

- [x] 1.1 Atualizar `--color-primary` para `#7132f5` no tema `light` em `assets/css/app.css`
- [x] 1.2 Atualizar `--color-primary-content` para `#ffffff`
- [x] 1.3 Atualizar `--color-secondary` para `#5741d8`
- [x] 1.4 Atualizar `--color-secondary-content` para `#ffffff`
- [x] 1.5 Atualizar `--color-base-100` para `#ffffff`
- [x] 1.6 Atualizar `--color-base-content` para `#101114`
- [x] 1.7 Atualizar `--color-base-200` para `#f5f5f7`
- [x] 1.8 Atualizar `--color-base-300` para `#dedee5`
- [x] 1.9 Atualizar `--color-success` para `#149e61`
- [x] 1.10 Atualizar `--color-success-content` para `#026b3f`
- [x] 1.11 Atualizar `--radius-box` para `0.75rem` (12px)

## 2. Tema daisyUI — dark

- [x] 2.1 Atualizar `--color-base-100` para `#13131f` no tema `dark`
- [x] 2.2 Atualizar `--color-base-200` para `#1a1a2e`
- [x] 2.3 Atualizar `--color-base-300` para `#25253a`
- [x] 2.4 Atualizar `--color-base-content` para `#e8e9f0`
- [x] 2.5 Atualizar `--color-primary` para `#9b72fb`
- [x] 2.6 Atualizar `--color-primary-content` para `#ffffff`
- [x] 2.7 Atualizar `--color-secondary` para `#7b6de0`
- [x] 2.8 Atualizar `--radius-box` para `0.75rem` (12px)

## 3. Tipografia

- [x] 3.1 Adicionar `<link>` do Google Fonts (IBM Plex Sans, weights 400/600/700) no `<head>` de `root.html.heex`
- [x] 3.2 Declarar variáveis de fonte em `app.css`: `--font-kraken-brand` e `--font-kraken-product` com as fallback stacks corretas
- [x] 3.3 Adicionar classes utilitárias de fonte no CSS (ex: `.font-brand`, `.font-product`) para uso nos templates

## 4. `core_components.ex` — button

- [x] 4.1 Adicionar `variant="outlined"` ao attr `:variant` do `<.button>`
- [x] 4.2 Substituir classes daisyUI do variant `primary` por `bg-[#7132f5] text-white rounded-xl px-4 py-[13px] text-base font-medium`
- [x] 4.3 Implementar variant `outlined`: `bg-white text-[#5741d8] border border-[#5741d8] rounded-xl px-4 py-[13px] text-base font-medium`
- [x] 4.4 Atualizar variant `nil` (default) para usar o mesmo estilo do `primary`

## 5. `core_components.ex` — header

- [x] 5.1 Adicionar `font-[Kraken-Brand]` (ou `font-brand`) e `font-bold` ao `h1` dentro do `<.header>`

## 6. Home page

- [x] 6.1 Remover o bloco SVG de fundo (o gradiente laranja/vermelho) de `home.html.heex`
- [x] 6.2 Aplicar superfície branca e texto `text-[#101114]` ao container principal
- [x] 6.3 Aplicar tipografia Kraken-Brand ao heading principal
- [x] 6.4 Substituir o botão `btn btn-primary` por botão com classes Kraken Primary
- [x] 6.5 Verificar que nenhuma cor Phoenix-orange permanece na página

## 7. Verificação final

- [x] 7.1 Rodar `mix precommit` e corrigir eventuais problemas
- [x] 7.2 Verificar visualmente a home page no browser (light mode)
- [x] 7.3 Verificar visualmente com dark mode ativo
- [x] 7.4 Verificar páginas de auth (`/sign_in`, `/register`) — confirmar herança de cores via tema
