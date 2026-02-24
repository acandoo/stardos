default:
    @just --list

# setup scripts

# Setup the repository for first use
[parallel]
setup: _setup-javascript _setup-gleam _setup-hooks

# Setup the repository for first use without installing the pre-commit hook
[parallel]
setup-no-hooks: _setup-javascript _setup-gleam

_setup-javascript:
    pnpm install

_setup-gleam:
    gleam deps download

_setup-hooks:
    node dev/setup-hooks.mjs

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
