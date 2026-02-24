# Contributing to `stardos`

Thank you for your interest in stardos!

## Bug reports

Please check for existing issues before opening up a bug report, and if there is no duplicate, open a new one!

## Contributing code

If you want to contribute code to the project, check the project's [issue tracker](https://github.com/acandoo/stardos/issues) for bugs to work on.

### Requirements

Aside from Gleam, the following software is expected in development:

- [pnpm](https://pnpm.io/) for installing and managing dependencies. It is also recommended to manage Node versions through `pnpm`.
- [Node](https://nodejs.org), [Deno](https://deno.com/), and [Bun](https://bun.com/) for testing all of the runtimes supported.
- [Just](https://just.systems/) for running common commands and tasks. As this project deals heavily with JavaScript FFI, Just is used to simplify managing tooling.

### Setup

Just run `just setup`!

The recipe will install Gleam and JavaScript dependencies, as well as install hooks to format and test your changes before committing, and install new dependencies on pull. If you don't want the hooks set up, run `just setup-no-hooks`. From there, the other `just` commands are your friends.

### AI usage

This repository allows any AI-assistance or AI agent workflows in contributing, but please do mind that any pull requests or issues that add files like AGENTS.md, CLAUDE.md, Cursor rules, MCP servers, etc. will not be accepted. It is much more valuable to spend that time creating and improving documentation for humans than it is for AI agents, who IMO should be using repository heuristics like README.md, CONTRIBUTING.md, docs/\*\*.md, etc. at the end of the day.

A rule of thumb for AI usage is that it should only ever _enhance_ the quality of your code, and never produce a worse result than if you were to write the code by hand. So, AI autocomplete, debugging, commit message drafting, code review, etc. are all allowed uses of AI, but "agentic" pull request creation without human oversight will very likely result in bad code quality and the pull request getting rejected.

### AI usage

This repository allows any AI-assistance or AI agent workflows in contributing, but please do mind that any pull requests or issues that add files like AGENTS.md, CLAUDE.md, Cursor rules, MCP servers, etc. will not be accepted. It is much more valuable to spend that time creating and improving documentation for humans than it is for AI agents, who IMO should be using repository heuristics like README.md, CONTRIBUTING.md, docs/\*\*.md, etc. at the end of the day.

A rule of thumb for AI usage is that it should only ever _enhance_ the quality of your code, and never produce a worse result than if you were to write the code by hand. So, AI autocomplete, debugging, commit message drafting, code review, etc. are all allowed uses of AI, but "agentic" pull request creation without human oversight will very likely result in bad code quality and the pull request getting rejected.
