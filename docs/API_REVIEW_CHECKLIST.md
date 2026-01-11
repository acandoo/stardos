# API Review Checklist — Stardos OS Library

This document confirms consistency, idiomaticity, and completeness of the Stardos API design.

## ✓ Consistency Checks

### Error Handling

- [x] All modules reference unified `IoError` from `DESIGN_SUMMARY.md`
- [x] Return types are consistent: `Result(T, IoError)` for fallible, `Option(T)` for optional
- [x] No duplicate error type definitions across modules
- [x] `env` module uses `IoError` (removed local `EnvError` type)

### Type Naming

- [x] Platform identifiers: `Linux`, `MacOS`, `Windows` (fixed `MacOs` → `MacOS`)
- [x] Signal type shared via reference: `PROCESS_API.md` → `SIGNAL_API.md`
- [x] Stream types consolidated: single `StdStream` type (removed duplicate `StreamType`)
- [x] `Stdio` type comments standardized with inline documentation

### Function Naming

- [x] Accessor functions: `get`, `set`, `remove` pattern consistent across modules
- [x] Query functions: `is_readable`, `is_writable` return `Bool`
- [x] Convenience getters: `get_or`, `now_millis`, `now_seconds`, `width`, `height`
- [x] Lifecycle functions: `spawn`, `wait`, `kill`, `close` naming stable

### Documentation Structure

- [x] Each module has: Core principle, Types, API, Cross-target notes, Examples, Summary
- [x] Function docs: name, signature, purpose, notes, examples
- [x] Cross-target compatibility tables use consistent symbols: ✓ (supported), ⚠️ (partial), ❌ (unsupported)
- [x] Examples use realistic, executable-style code

## ✓ Idiomaticity Checks

### Result-First Design

- [x] High-level APIs return `Result` at Gleam level (no callbacks in user code)
- [x] Fallible operations documented with error cases
- [x] Pattern-matching examples shown in most modules

### IoDevice Abstraction

- [x] Process stdin/stdout/stderr return `IoDevice`
- [x] File I/O built on `IoDevice` (planned via `stardos/fs`)
- [x] Generic operations: `read`, `write`, `close`, `copy` work across device types
- [x] Optional operations: `seek`, predicates return `Error(io.Unsupported)` when unavailable

### API Minimalism

- [x] No redundant convenience functions (e.g., single `size()` covers both `width` and `height`)
- [x] Parameter names clear and consistent: `given:` for optional context, `then:` for callbacks (where used)
- [x] Removed redundant "Design notes" sections in favor of inline documentation

### Composability

- [x] Signal type used in both `process.kill()` and `signal.send()`
- [x] `StdStream` type shared between stdio and process modules
- [x] IoDevice enables generic piping without module-specific wrappers

## ✓ Completeness Checks

### Module Coverage

- [x] I/O: `io/device`, `io/stdio` defined and integrated
- [x] Process: `spawn`, `run`, `wait`, `kill`, device accessors, signal integration
- [x] Environment: variables, cwd, home/temp, user helpers
- [x] System: platform, arch, hostname, CPU, uptime, load
- [x] Time: wall-clock, monotonic, sleep, timezone
- [x] User: current user, lookup, groups
- [x] Signals: send, handlers, ignore, default
- [x] Resource: usage, limits, CPU/memory/FD inspection
- [x] Terminal: TTY detection, size, raw mode, cursor control

### Cross-Target Documentation

- [x] BEAM: all operations synchronous where possible
- [x] Node: async operations wrapped as sync `Result` API
- [x] Browser: limited operations return `Unsupported` or degrade gracefully
- [x] All modules have cross-target compatibility table

### Examples Provided

- [x] Simple cases (e.g., `env.get_or("PORT", "8080")`)
- [x] Pattern-matching cases (e.g., `case process.run(...)`)
- [x] Integration examples (e.g., piping process stdout to parent stdout)
- [x] Error handling examples
- [x] Real-world patterns (graceful shutdown, resource monitoring, TTY detection)

## ✓ No Duplication

### Types

- [x] `Signal` defined once in `SIGNAL_API.md`, referenced in `PROCESS_API.md`
- [x] `IoError` defined once in `DESIGN_SUMMARY.md`, referenced in all modules
- [x] `StdStream` defined once in `IO_DEVICE_API.md`, used by both stdio and process
- [x] No redundant error type definitions per module

### Documentation

- [x] Error handling explained once in `DESIGN_SUMMARY.md`; modules link to it
- [x] Cross-target notes follow a consistent format across all modules
- [x] Core principles are concise and module-specific (no repetition)
- [x] Design rationale consolidated in `DESIGN_SUMMARY.md`

## ✓ Idiomatic with Other Languages

### Rust Influences

- [x] `std::fs` / `std::process` / `std::env` split reflected in module layout
- [x] `Result`-first API matches `std::io::Result`
- [x] `Stdio` type mirrors `std::process::Stdio`

### Python Influences

- [x] `env.get_or()` convenience method like `os.getenv(key, default)`
- [x] Process module mirrors `subprocess` API (run, spawn, wait)
- [x] Time module follows `time` module structure

### Go Influences

- [x] Module focus: separate concerns (env, os, process, time, user)
- [x] Error handling: `Result(T, IoError)` similar to Go's `(T, error)` tuple

### Node.js Influences

- [x] `fs/promises` ergonomics reflected in synchronous Result API
- [x] Process stdio via device abstraction similar to stream objects

## ✓ Future-Proofing

### Extensibility Points

- [x] `IoDevice` designed to support sockets, PTYs, pipes (not just files)
- [x] Module nesting pattern (e.g., `stardos/io/stdio`) allows easy additions (helpers, advanced features)
- [x] `Custom(Int)` variant in `Signal` allows platform-specific signals
- [x] `Unknown(String)` variants in `Platform` and `Arch` for future platforms
- [x] `Option` return types used where graceful fallback is appropriate

### Implementation Flexibility

- [x] Thin FFI layer planned; high-level API stable across targets
- [x] Synchronous-looking Gleam API can wrap async JS/Node operations
- [x] Error type allows addition of new variants without breaking existing code

## Summary

**All aspects of the API design have been reviewed and streamlined:**

- ✓ No duplicate type definitions or documentation
- ✓ Consistent error handling and return types across all modules
- ✓ Idiomatic naming and structure (Gleam, Rust, Python, Go conventions)
- ✓ Complete module coverage with realistic examples
- ✓ Clear cross-target compatibility documented
- ✓ Future-proof design with extensibility points

The API is ready for implementation. Begin with Phase 1 (FFI stubs and Gleam wrappers for core modules).
