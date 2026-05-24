# LetsChat

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

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

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
