# Agent Design Context

## Purpose

Define how design system documentation is structured and surfaced to AI agents working on the `lets_chat` project, ensuring consistent design decisions through progressive disclosure and a dedicated namespace for agent context files.

## Requirements

### Requirement: Design system doc em `.agents/docs/`
O projeto SHALL ter um arquivo `.agents/docs/design-system.md` contendo o design system em formato agent-optimized: paleta de cores com valores hex/rgba, hierarquia tipográfica, variantes de botões com valores exatos, badges, shadows, spacing scale, border radius scale, breakpoints responsivos, e do's/don'ts.

#### Scenario: Doc presente e acessível
- **WHEN** o agente precisa de referência de design ao trabalhar em UI
- **THEN** `.agents/docs/design-system.md` existe e contém tokens de cor, tipografia e componentes

#### Scenario: daisyUI coexistência documentada
- **WHEN** o agente lê `.agents/docs/design-system.md`
- **THEN** o documento deixa explícito que daisyUI coexiste e o design system é aditivo

### Requirement: Progressive disclosure via `lib/lets_chat_web/AGENTS.md`
O diretório `lib/lets_chat_web/` SHALL conter um `AGENTS.md` com as regras críticas do design system inline (cores, tipografia, botões) e referência ao doc completo em `.agents/docs/design-system.md`.

#### Scenario: AGENTS.md carregado automaticamente no web layer
- **WHEN** o agente edita qualquer arquivo em `lib/lets_chat_web/`
- **THEN** `lib/lets_chat_web/AGENTS.md` é carregado e as regras de design ficam disponíveis no contexto

#### Scenario: Cores primárias presentes inline
- **WHEN** `lib/lets_chat_web/AGENTS.md` é lido
- **THEN** contém `#7132f5` como token de CTA/brand e `#101114` como token de texto primário

#### Scenario: Regra de botões presente inline
- **WHEN** `lib/lets_chat_web/AGENTS.md` é lido
- **THEN** contém instrução explícita de que `rounded-xl` (12px) é o radius máximo para botões

### Requirement: Namespace `.agents/docs/` para contexto não-usage_rules
O projeto SHALL usar `.agents/docs/` como diretório dedicado a arquivos de contexto de IA que não são gerenciados pelo `usage_rules`, separado de `.agents/skills/` (gerenciado) e `.agents/commands/`.

#### Scenario: Separação de namespaces
- **WHEN** um novo documento de contexto de IA é adicionado ao projeto (ex: guia de produto, decisões de arquitetura)
- **THEN** o arquivo é criado em `.agents/docs/` e não em `.agents/skills/`
