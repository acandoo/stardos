# Stardos — Complete OS API Design Summary

This file summarizes the batteries-included OS library design and outlines next steps for implementation.

## Overview

Stardos aims to provide a comprehensive, ergonomic API for OS-level operations in Gleam. The design emphasizes **one clear, high-level way** to accomplish common tasks while remaining extensible and composable.

## Module Relationships and Dependencies

```
stardos/io (facade)
├── stardos/io/device (core abstraction)
├── stardos/io/stdio (standard streams)
└── stardos/io/term (TTY detection and control)

stardos/env (process config)
└── uses: stardos/process (spawn with env)

stardos/process (child processes)
├── returns: IoDevice for stdin/stdout/stderr
├── uses: stardos/signal (kill)
└── uses: stardos/env (inherit environment)

stardos/os (system info, read-only)
stardos/time (clocks and delays)
stardos/user (user/group lookups, read-only)
stardos/signal (signal handling)
stardos/resource (process metrics, read-only)
stardos/term (TTY control)
```

**Key design pattern:** All modules use `IoError` for errors and return `Result` or `Option` at the Gleam API level. I/O operations expose `IoDevice` for composability.

### I/O and Devices

- **`stardos/io/device`** — Generic `IoDevice` abstraction (files, sockets, pipes, TTYs). Minimal operations: `read`, `write`, `close`, `seek`.
- **`stardos/io/stdio`** — Standard streams (stdin, stdout, stderr) and convenience functions (print, println, eprint, eprintln, read_line, isatty).
- **`stardos/io/file`** — File-specific FFI (already exists; callback-based). Will be wrapped by higher-level fs helpers.
- **`stardos/io`** — Facade re-exporting device, stdio, and optionally file.

### Filesystem (user's domain; documented separately)

- **`stardos/fs`** (or submodules `stardos/io/fs/*`) — High-level file/directory operations (read_text, write_text, exists, mkdir, etc.) built atop `stardos/io/file` FFI and `IoDevice`.

### Environment and Process Control

- **`stardos/env`** — Process-scoped configuration: environment variables (`get`, `set`, `remove`, `vars`), working directory (`cwd`, `chdir`), user/home/temp helpers.
- **`stardos/process`** — Child process spawning and management: `run` (simple), `spawn` (with stdio/env/cwd options), `wait`, `try_wait`, `kill`, device accessors, `detached`.
- **`stardos/signal`** — POSIX signal sending and handling: `send`, `set_handler`, `ignore`, `default`.

### System Information

- **`stardos/os`** — Host/system info: `platform`, `arch`, `hostname`, `num_cpus`, `uptime`, `load_average`, `kernel_version`, `os_release_info`.
- **`stardos/time`** — Clocks and delays: `now`, `monotonic_now`, `elapsed`, `sleep`, timezone helpers.
- **`stardos/user`** — User/group info: `current_user`, `lookup_user`, `lookup_group`, group membership.
- **`stardos/resource`** — Process resource usage: `current_usage`, `limit`, `set_limit`, CPU/memory/FD inspection.

- **`stardos/io/term`** — TTY detection and control: `isatty`, `size`, `enable_raw_mode`, `disable_raw_mode`, cursor control, `clear_screen`.

## Design Principles (Recap)

1. **Ergonomic high-level API**: `Result(T, IoError)` or `Option(T)` return types. One clear way per task.
2. **Composability**: `IoDevice` abstraction allows generic piping and streaming; process stdio, files, and sockets share a common interface.
3. **Cross-target support**: Stable API shape across BEAM, Node.js, and browser. Document which operations are available per target.
4. **Thin FFI layer**: Low-level, callback-based FFI functions (like existing `stardos/io/file` functions) implement portability. Gleam wrappers provide ergonomics.

## API Characteristics by Module

| Module      | Main Types                                          | Return Style            | Async?          | Platform Support              |
| ----------- | --------------------------------------------------- | ----------------------- | --------------- | ----------------------------- |
| `io/device` | `IoDevice`, `SeekWhence`                            | `Result`                | Sync API        | BEAM, Node, Browser (partial) |
| `io/stdio`  | `StdStream`                                         | `Result`, convenience   | Sync API        | BEAM, Node (partial)          |
| `env`       | `EnvError` (optional)                               | `Result`, `Option`      | Sync            | BEAM, Node                    |
| `process`   | `ProcessHandle`, `ProcessOutput`, `Signal`, `Stdio` | `Result`                | Sync wrapper    | BEAM, Node                    |
| `signal`    | `Signal`, `SignalHandler`                           | `Result`                | Async (signals) | BEAM, Node                    |
| `os`        | `Platform`, `Arch`                                  | `Result`, direct return | Sync            | BEAM, Node, Browser (partial) |
| `time`      | `SystemTime`, `Instant`                             | `Result`, direct return | Sync            | BEAM, Node, Browser           |
| `user`      | `UserInfo`, `GroupInfo`                             | `Option`, `Result`      | Sync            | BEAM, Node (Unix)             |
| `resource`  | `ResourceUsage`, `Limit`, `LimitKind`               | `Result`, `Option`      | Sync            | BEAM, Node                    |
| `term`      | `TerminalSize`, `TerminalMode`                      | `Result`, `Option`      | Sync            | BEAM, Node (partial)          |

## Implementation Strategy | `Result`

### Phase 1: Foundation (Priority)

1. **Implement thin FFI stubs** for each target (BEAM, Node, browser):

   - `stardos/io/device` FFI functions: `read`, `write`, `close`, `seek`.
   - `stardos/io/stdio` FFI: `stdin`, `stdout`, `stderr`, `isatty`.
   - Process, signal, time, and system info stubs.

2. **Create Gleam wrappers** that call the FFI and return `Result(T, IoError)`:

   - `stardos/env.gleam` wrapping env FFI.
   - `stardos/process.gleam` wrapping process FFI.
   - `stardos/io/stdio.gleam` and `stardos/io/device.gleam` convenience wrappers.
   - `stardos/os.gleam`, `stardos/time.gleam`, etc.

3. **Define a unified `IoError` type**:

   - Cover all error cases across modules (not found, permission denied, unsupported, system error, etc.).
   - Provide helpers to convert target-specific errors to the unified type.

4. **Tests and examples** under `test/`:
   - Demonstrate each module's key APIs.
   - Include integration examples (e.g., spawn a process and pipe its output).

### Phase 2: Polish

1. **Re-export and organize facades** (`stardos/io`, `stardos/os`, etc.) for ergonomic imports.
2. **Extend with convenience helpers** (e.g., `read_text_safe`, `retry_with_backoff`, etc.) based on real-world patterns.
3. **Full documentation**: README, module docs, FAQ, migration guide.

### Phase 3: Extensibility

1. **Add `stardos/os/unix`** for Unix-specific escape hatches (raw syscalls, ioctl, etc.).
2. **Add `stardos/net`** (future) for socket/networking support (shares `IoDevice` abstraction).
3. **Add `stardos/io/helpers`** for streaming combinators (tee, filter, transform, etc.).

## Naming Conventions

- **Modules**: lowercase, separated by `/` for nesting (e.g., `stardos/io/device`).
- **Types**: `PascalCase` (e.g., `IoDevice`, `ProcessHandle`).
- **Functions**: `snake_case` (e.g., `read_all`, `current_pid`).
- **Error variants**: `PascalCase` (e.g., `NotFound`, `PermissionDenied`).
- **Constants/Type discriminants**: `PascalCase` (e.g., `Linux`, `Windows`).

## Unified Error Type

The `stardos/io` module defines a unified `IoError` type used across all OS operations:

- `NotFound(path)` — file/resource not found
- `PermissionDenied` — insufficient permissions
- `AlreadyExists` — file/resource already exists
- `InvalidInput` / `InvalidArgument` — bad argument
- `TimedOut` — operation timeout
- `Interrupted` — system call interrupted
- `Unsupported(operation)` — feature not available on this target/platform
- `NotReadable` / `NotWritable` — I/O direction mismatch
- `BrokenPipe` — pipe closed
- `SystemError(code, message)` — low-level OS error

All modules (`env`, `process`, `time`, etc.) return `Result(T, IoError)` or `Option(T)` for consistency.

## Cross-Target Implementation Notes

### BEAM (Erlang)

- Most operations are synchronous; map directly to Erlang built-ins.
- Use `erlang:open_port/2` for process spawning.
- File I/O via `file:*` modules.
- Use `os:*` for system info.

### Node.js

- File I/O, process spawning, system info all available via Node APIs.
- Some operations are async (Promises); wrap with Gleam helpers to present sync `Result` API.
- Environment variables via `process.env`.
- Use `child_process` module for spawning.

### Browser

- Very limited OS access (sandboxed, no file I/O, no subprocess, no env vars).
- Expose read-only data (platform, arch) via user agent.
- Return `Unsupported` errors for unavailable operations.
- Optionally provide polyfills or alternative implementations (e.g., IndexedDB for "filesystem").

## Documentation Artifacts

- **API_PROPOSAL.md** — Initial high-level design and goals.
- **IO_ENV_OS_GUIDE.md** — Clarification of module responsibilities and placement of stdio.
- **OS_NON_IO_API.md** — Initial sketch (superseded by detailed modules).
- **PROCESS_API.md** — Detailed process module design.
- **ENV_API.md**, **OS_API.md**, **IO_DEVICE_API.md**, **SIGNAL_API.md**, **TIME_API.md**, **USER_API.md**, **RESOURCE_API.md**, **TERM_API.md** — Detailed module designs.

## Next Steps (Actionable)

1. Define the unified `IoError` type in `stardos/io`.
2. Implement thin FFI stubs for each target (start with Node for ergonomics).
3. Create Gleam wrappers for `stardos/env`, `stardos/process`, `stardos/time`, and `stardos/os`.
4. Add tests demonstrating the APIs.
5. Iterate based on real-world usage patterns.

## Conclusion

This design provides a comprehensive, ergonomic OS library that:

- Follows one-way-to-do-it principle while remaining extensible.
- Integrates seamlessly across modules via the `IoDevice` abstraction.
- Maintains consistent, easy-to-learn API surface.
- Supports multiple targets (BEAM, Node, browser) with stable API shape.

The detailed module docs above serve as a specification for implementation.
