# LetsChat

A real-time chat application built with Phoenix 1.8, Ash Framework 3.0, AshPostgres, and live_vue.

## Development

### Prerequisites

- [mise](https://mise.jdx.dev/) for runtime version management

### Getting started

```sh
# Install Erlang 27.3, Elixir 1.18.3-otp-27, and Node.js 22.14.0
# (also runs mix deps.get automatically via postinstall hook)
mise install

# Create and migrate the database, compile assets
mise run setup
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### mise tasks

| Task | Command | Description |
|------|---------|-------------|
| `setup` | `mise run setup` | Install deps, create and migrate the database, compile assets |
| `server` | `mise run server` | Start the Phoenix dev server |
| `test` | `mise run test` | Run the test suite |
| `precommit` | `mise run precommit` | Run all quality checks before committing |

All tasks are also available via their `mix` equivalents (e.g. `mix phx.server`).

## CI / Code Quality

Every push and pull request to `main` runs the full CI pipeline on GitHub Actions. Steps run in order, from fastest to slowest, so trivial failures surface early:

| Step | Command |
|------|---------|
| Compile | `mix compile --warnings-as-errors` |
| Formatting | `mix format --check-formatted` |
| Unused deps | `mix deps.unlock --check-unused` |
| Hex audit | `mix hex.audit` |
| Security audit | `mix deps.audit` |
| Credo (strict) | `mix credo --strict` |
| Sobelow | `mix sobelow --skip --exit Low` |
| Dialyzer | `mix dialyzer` |
| Tests | `mix test` |

Run the same checks locally before pushing:

```sh
mix precommit
```

> **Note:** Node.js / Vite assets are not built in CI. `live_vue` uses `ssr_module: nil` in the test env, so no JS runtime is needed. If tests that require compiled Vue SSR assets are added in the future, a build step will need to be added.

## Claude Code setup

All Claude Code configuration lives in `.agents/` (skills, commands, and MCP servers). This directory is the source of truth — never edit `.claude/` or `.mcp.json` directly.

After cloning, create the symlinks that Claude Code expects:

```sh
mkdir -p .claude
ln -s ../.agents/skills   .claude/skills
ln -s ../.agents/commands .claude/commands
ln -s .agents/mcp.json    .mcp.json
ln -s AGENTS.md           CLAUDE.md
```

The generated `.claude/` and `.mcp.json` are git-ignored, so each developer runs this once locally.

`AGENTS.md` has a managed section (between `<!-- usage-rules-start -->` and `<!-- usage-rules-end -->`) that is auto-generated from dependency usage rules — never edit it manually. After upgrading dependencies, run `mix usage_rules.sync --yes` to keep it up to date.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
