# Stardos: IoDevice, stdio placement, and `env` vs `os` split

This note records recommended placement and module layout for `IoDevice`/stdio and clarifies the split between `stardos/env` and `stardos/os`. It also documents module path patterns (nested modules) and re-export facades.

1. Where should `stdin`, `stdout`, `stderr` IoDevices live?

- Place the core abstraction in a small module `stardos/io/device` (or `stardos/io_device`). This module defines the type and low-level operations, e.g.:

  - `stardos/io/device` — defines `type IoDevice`, the minimal operation set (`read`, `write`, `close`, `seek` optional), and helper adapters (buffered wrappers, conversion helpers).

- Provide a dedicated stdio module for the standard streams: `stardos/io/stdio` (path-style to match other nested modules). This module exports:

  - `stdin: () -> IoDevice`
  - `stdout: () -> IoDevice`
  - `stderr: () -> IoDevice`
  - convenience helpers: `print`, `println`, `eprint`, `eprintln`, `read_line`, etc.

- Re-export the stdio and device types from the top-level `stardos/io` facade so callers can import just `stardos/io` for common cases.

Why not `env`?

- `env` models process-level environment _state_ (variables, cwd); stdio are active I/O endpoints and belong conceptually to the I/O subsystem. Mixing them dilutes module cohesion and makes imports confusing (e.g., `import stardos/env` to get `stdout` is surprising).

2. `env` vs `os` — a clear split

Core rule: `env` is _process-scoped configuration and environment_; `os` is _host/system-scoped information and control_.

- `stardos/env` (process scope)

  - get/set/remove environment variables: `get`, `set`, `remove`, `vars`.
  - process working directory helpers: `cwd`, `chdir`.
  - per-process helpers closely tied to the running process: `argv` (or `stardos/argv`), `umask` (if considered process-local), `temp_dir()` and `home_dir()` (convenience accessors that reflect the running process's environment).
  - Any API that only affects the current process belongs here.

- `stardos/os` (system scope)
  - host identification and metrics: `platform`, `arch`, `hostname`, `num_cpus`, `uptime`, `load_average`.
  - system-level control and privileged ops (if supported by the runtime): `reboot`, `shutdown`, `set_system_timezone` (document as platform-specific and likely `Error(io.Unsupported)` on many targets).
  - kernel/OS metadata: `kernel_version`, `os_release`, `distributions` (if applicable).
  - low-level system resource inspection or submodules (e.g., `stardos/os/resource` for `resource_usage`) — these may be grouped under `stardos/os/*`.

Examples

- `stardos/env` usage (process-scoped):

  - `let maybe_port = env.get("PORT")`
  - `env.chdir("/tmp")`

- `stardos/os` usage (system-scoped):

  - `let platform = os.platform()`
  - `let cpus = os.num_cpus()`

3. Module path patterns and re-exports

- Use nested modules to group related functionality, following existing pattern `stardos/concurrent/future`:

  - `stardos/io/device` — core IoDevice abstraction
  - `stardos/io/stdio` — standard streams convenience
  - `stardos/io/file` — file-specific FFI and helpers (already present)
  - `stardos/os/info` and/or `stardos/os/control` for logical grouping under `os`

- Provide small top-level facades that re-export the ergonomic surface for common use:

  - `stardos/io` re-exports `device` and `stdio` (and optionally `file`) so callers can `import stardos/io` and access what they need.
  - `stardos/os` re-exports `os/info` items like `platform()` and `num_cpus()`.

4. Mapping of concerns to modules (cheat sheet)

- Standard streams: `stardos/io/stdio`, re-exported via `stardos/io`.
- Generic IO devices and adapters: `stardos/io/device`.
- Filesystem FFI: `stardos/io/file` (existing).
- Environment variables, cwd: `stardos/env`.
- Process management: `stardos/process` (spawn/run/wait/kill). Process-level stdio will be exposed as `IoDevice` instances (from `stardos/io/device`) returned by `stardos/process/spawn`.
- Signals: `stardos/signal` (or `stardos/os/signal` if you prefer nesting under `os`).
- System info and control: `stardos/os/*`.

5. Cross-target considerations & doc guidance

- Top-level API shapes should be stable across targets. Document target-specific limitations: browser lacks stdio/process/system APIs; Node has async semantics; BEAM can implement sync versions.
- For stdio, document the guarantees per target: e.g., Node and BEAM provide stdin/stdout/stderr; browsers do not (or map to console). `stardos/io/stdio` functions should return `Error(io.Unsupported)` or `Option` where not available.

6. Implementation ergonomics (docs-only notes)

- Keep device ops minimal and composable; build higher-level helpers (`read_all`, `write_all`, `lines`) in `stardos/io` or `stardos/io/helpers`.
- When `stardos/process.spawn` returns streaming I/O handles, they should be `IoDevice` variants so user code can `copy`/`pipe` between devices generically.

7. Quick import examples

- Use stdio and device via facade:

```gleam
import stardos/io

let out = io.stdout()
io.println("hello")
```

- Spawn a process and pipe stdout to program stdout (conceptual):

```gleam
import stardos/process
import stardos/io

use handle <- process.spawn("ls", ["-la"]) // returns ProcessHandle with device pipes
let stdout_dev = process.stdout_device(handle)
io.copy(stdout_dev, io.stdout())
```

Closing notes

- This layout keeps I/O concerns in `stardos/io*`, local process settings in `stardos/env`, and machine-wide capabilities in `stardos/os`. It supports a small `IoDevice` abstraction for future-proofing sockets, ptys, and process pipes while preserving ergonomics via facades and nested modules.
