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

The recipe will install Gleam and JavaScript dependencies, as well as install a pre-commit git hook to format and test your changes before committing. If you don't want the hooks set up, run `just setup-no-hook`. From there, the other `just` commands are your friends.
