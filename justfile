default:
    @just --list

# setup scripts

# Setup the repository for first use
[parallel]
setup: _setup-javascript _setup-gleam _setup-hook

_setup-javascript:
    pnpm install

_setup-gleam:
    gleam deps download

_setup-hook:
    #!/bin/env node
    import fs from 'node:fs/promises'
    import path from 'node:path'

    await fs.chmod(path.join('dev', 'pre-commit'), 0o755)
    const preCommitHookPath = path.join('.git', 'hooks', 'pre-commit')
    const preCommitHookOldPath = path.join('.git', 'hooks', 'pre-commit.old')
    await fs.rename(preCommitHookPath, preCommitHookOldPath).catch(() => {})

    const relativeSymlinkPath = path.relative(path.join('.git', 'hooks'), path.join('dev', 'pre-commit'))
    await fs.symlink(relativeSymlinkPath, preCommitHookPath)

# test scripts

# Run all tests for JavaScript and Erlang targets, and check formatting
[parallel]
test: test-javascript test-erlang format-check

alias test-js := test-javascript

# Run tests for JavaScript target across all runtimes
[parallel]
test-javascript: test-node test-deno test-bun

# Run tests for Node.js runtime
test-node: build-javascript
    gleam test -t javascript --runtime node

# Run tests for Deno runtime
test-deno: build-javascript
    gleam test -t javascript --runtime deno

# Run tests for Bun runtime
test-bun: build-javascript
    gleam test -t javascript --runtime bun

alias test-erl := test-erlang

# Run tests for Erlang target
test-erlang:
    gleam test -t erlang

# build scripts

# Build both JavaScript and Erlang targets
[parallel]
build: build-javascript build-erlang

# Build JavaScript target (including FFI generation)
build-javascript:
    node ./dev/build-ffi.mjs
    gleam build -t javascript

alias build-js := build-javascript

# Build Erlang target
build-erlang:
    gleam build -t erlang

alias build-erl := build-erlang

# Automatically build FFIs for development
watch:
    node ./dev/watch.mjs

# formatting/linting scripts

# Format all code
[parallel]
format: _format-gleam _format-javascript

alias fmt := format

_format-gleam:
    gleam format

_format-javascript:
    ./node_modules/.bin/oxfmt

[parallel]
format-check: _format-check-gleam _format-check-javascript

_format-check-gleam:
    gleam format --check src test dev

_format-check-javascript:
    ./node_modules/.bin/oxfmt --check
