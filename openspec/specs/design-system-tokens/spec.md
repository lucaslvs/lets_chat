# Design System Tokens

## Purpose

Specifies how the application's visual design tokens — colors, typography, and component styles — map to the Kraken design system. Covers daisyUI theme configuration, font family declarations, and component-level style requirements.

## Requirements

### Requirement: Light theme uses Kraken color tokens
The application's daisyUI light theme SHALL use Kraken color tokens as CSS custom properties, replacing the Phoenix scaffold defaults.

#### Scenario: Primary color is Kraken Purple
- **WHEN** any daisyUI component renders with `btn-primary`, `text-primary`, or `bg-primary`
- **THEN** the color is `#7132f5` (Kraken Purple)

#### Scenario: Primary content color ensures contrast
- **WHEN** text is rendered over a `bg-primary` surface
- **THEN** the text color is `#ffffff`

#### Scenario: Base content color is Near Black
- **WHEN** body text renders without explicit color override
- **THEN** the color is `#101114`

#### Scenario: Secondary color is Purple Dark
- **WHEN** any component uses `text-secondary` or `border-secondary`
- **THEN** the color is `#5741d8`

#### Scenario: Border radius matches Kraken spec
- **WHEN** daisyUI renders a box (card, modal, panel)
- **THEN** the radius is 12px (0.75rem)

---

### Requirement: Dark theme uses Kraken navy palette
The application's daisyUI dark theme SHALL use Kraken-adapted dark tokens — navy surfaces with increased-lightness purple.

#### Scenario: Dark base surface is navy
- **WHEN** `data-theme="dark"` is active on `<html>`
- **THEN** the base-100 surface color is `#13131f`

#### Scenario: Dark primary is readable on dark surface
- **WHEN** `data-theme="dark"` is active and a primary button is rendered
- **THEN** the button background is `#9b72fb` (lightness-increased Kraken Purple)

#### Scenario: Dark base content is near-white
- **WHEN** `data-theme="dark"` is active and body text renders
- **THEN** the text color is `#e8e9f0`

---

### Requirement: Typography uses Kraken font families
The application SHALL declare `Kraken-Brand` and `Kraken-Product` font families with correct fallbacks, used consistently across the interface.

#### Scenario: Heading font family falls back correctly
- **WHEN** `Kraken-Brand` font is not loaded
- **THEN** the browser uses IBM Plex Sans, then Helvetica, then Arial

#### Scenario: Body font family falls back correctly
- **WHEN** `Kraken-Product` font is not loaded
- **THEN** the browser uses Helvetica Neue, then Helvetica, then Arial

#### Scenario: Font structure accepts real files without code changes
- **WHEN** `.woff2` files for Kraken-Brand and Kraken-Product are added to `assets/public/fonts/`
- **THEN** they can be referenced via `@font-face` declarations without changing any component or template code

---

### Requirement: Primary button follows Kraken spec
The `<.button>` component with `variant="primary"` SHALL render with Kraken Primary button tokens.

#### Scenario: Primary button visual spec
- **WHEN** `<.button variant="primary">` is rendered
- **THEN** background is `#7132f5`, text is white, radius is `rounded-xl` (12px), and padding is `px-4 py-[13px]`

#### Scenario: Outlined button visual spec
- **WHEN** `<.button variant="outlined">` is rendered
- **THEN** background is white, text is `#5741d8`, border is `1px solid #5741d8`, radius is `rounded-xl`

#### Scenario: Button never uses pill radius
- **WHEN** any button variant is rendered
- **THEN** border-radius SHALL NOT exceed 12px (`rounded-xl`)

---

### Requirement: Header component uses Kraken typography
The `<.header>` component SHALL apply Kraken-Brand font to its `h1` element.

#### Scenario: Header h1 uses display font
- **WHEN** `<.header>` is rendered
- **THEN** the `h1` uses `font-[Kraken-Brand]` (or equivalent Tailwind class) and `font-bold`

---

### Requirement: Home page does not use Phoenix scaffold styles
The `home.html.heex` SHALL NOT contain the Phoenix SVG background or any orange/red scaffold colors.

#### Scenario: Home page uses Kraken surface
- **WHEN** a user visits `/`
- **THEN** the page background is white (`#ffffff`) and primary text is `#101114`

#### Scenario: Home page CTA uses Kraken Primary button
- **WHEN** a user visits `/` and there is a primary call-to-action
- **THEN** the button uses Kraken Primary styles (`bg-[#7132f5]`, `rounded-xl`)
