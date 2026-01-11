# Stardos Implementation Roadmap

## Current Status: API Design Complete ✅

All modules have been designed with complete type signatures, examples, and cross-target compatibility notes. The API is idiomatic to Gleam and inspired by best practices from Rust, Python, Go, and Node.js.

### Completed Design Documents

- ✅ [DESIGN_SUMMARY.md](DESIGN_SUMMARY.md) — Overview, module map, design principles, implementation phases
- ✅ [ENV_API.md](ENV_API.md) — Environment variables, working directory, home/temp helpers
- ✅ [PROCESS_API.md](PROCESS_API.md) — Spawn, run, wait, kill, signal handling
- ✅ [IO_DEVICE_API.md](IO_DEVICE_API.md) — Generic IoDevice abstraction for files, sockets, pipes, TTYs
- ✅ [OS_API.md](OS_API.md) — Platform info, architecture, hostname, CPU count, uptime
- ✅ [TIME_API.md](TIME_API.md) — System/monotonic clocks, Duration, timezones, parsing
- ✅ [USER_API.md](USER_API.md) — Current user, lookups, group membership
- ✅ [RESOURCE_API.md](RESOURCE_API.md) — CPU/memory/FD metrics, resource limits
- ✅ [TERM_API.md](TERM_API.md) — TTY detection, size, raw mode, cursor control
- ✅ [SIGNAL_API.md](SIGNAL_API.md) — POSIX signal sending and handling
- ✅ [API_PROPOSAL.md](API_PROPOSAL.md) — Initial design goals and phased approach

### Design Highlights

**Module Organization:**

```
stardos/
├── env/              # Environment vars, cwd, home/temp
├── process/          # Child process spawning & control
├── signal/           # POSIX signal handling
├── os/               # System info (platform, arch, hostname, CPU, uptime)
├── time/             # Clocks, Duration, timezone
├── user/             # User/group lookups
├── resource/         # Process metrics (CPU, memory, FD)
└── io/
    ├── device/       # Generic IoDevice abstraction
    ├── stdio/        # stdin, stdout, stderr + helpers
    ├── file/         # File operations (existing FFI)
    └── term/         # TTY detection & control
```

**Idiomatic Return Types:**

- `Result(T, IoError)` — For I/O operations that can fail
- `Result(T, Nil)` — For queries/operations that may not succeed (no error info needed)
- `Bool` — For simple predicates (isatty, exists, is_available)

**Core Abstraction: `IoDevice`**

- Unified interface for files, sockets, pipes, TTYs
- Minimal operations: `read`, `write`, `close`, `seek`
- Returned by process spawning for stdin/stdout/stderr pipes

**Cross-Target Support:**

- **BEAM**: Synchronous implementations via Erlang primitives
- **Node.js**: Async operations wrapped to present sync `Result` API
- **Browser**: Graceful degradation; unsupported operations return `Error(Unsupported)`

---

## Implementation Phases

### Phase 1: Foundation (NEXT)

**Goal:** Get core infrastructure working (environment, time, basic process)

**Tasks:**

1. Define unified `IoError` type in `src/stardos/io.gleam`
2. Implement FFI stubs for BEAM, Node, browser targets:
   - Environment variables (get, set, remove)
   - Time (now, monotonic_now)
   - Process spawning (basic run/spawn)
   - System info (platform, arch, CPU count)
3. Create Gleam wrappers:
   - `src/stardos/env.gleam` (wraps env FFI)
   - `src/stardos/time.gleam` (wraps time FFI)
   - `src/stardos/os.gleam` (wraps os FFI)
4. Write tests in `test/` for each module

**Estimated effort:** 2-3 weeks (FFI learning curve + cross-target testing)

### Phase 2: I/O and Process Management

**Goal:** Implement process spawning and I/O device abstraction

**Tasks:**

1. Implement `IoDevice` abstraction in `src/stardos/io/device.gleam`
2. Implement stdio functions in `src/stardos/io/stdio.gleam` (print, println, read_line, isatty)
3. Implement `stardos/process.gleam` (spawn, run, wait, kill)
4. Implement `stardos/signal.gleam` (send_signal, set_handler)
5. Add tests for piping and stdio redirection

**Estimated effort:** 3-4 weeks

### Phase 3: System Queries (OS, User, Resource)

**Goal:** Expose read-only system information

**Tasks:**

1. Expand `os.gleam` (uptime, load_average, kernel_version)
2. Implement `src/stardos/user.gleam` (current_user, lookup_user, lookup_group)
3. Implement `src/stardos/resource.gleam` (CPU usage, memory, open FD count)
4. Add Unix-specific tests

**Estimated effort:** 2 weeks

### Phase 4: Advanced I/O (Terminal, File Helpers)

**Goal:** TTY control and high-level file/directory APIs

**Tasks:**

1. Implement `src/stardos/io/term.gleam` (size, raw_mode, cursor control)
2. Implement `src/stardos/fs/` or `src/stardos/io/fs/` helpers (read_text, write_text, exists, mkdir, etc.)
3. Wrap existing `src/stardos/io/file.gleam` FFI with ergonomic Gleam API

**Estimated effort:** 2-3 weeks

### Phase 5: Polish & Documentation

**Goal:** Production-ready library with examples and guides

**Tasks:**

1. Add comprehensive README with quickstart
2. Create example scripts demonstrating each module
3. Add performance notes and best practices guide
4. Publish package to Gleam registry

**Estimated effort:** 1-2 weeks

---

## Key Decision Points

1. **Filesystem vs. IoDevice integration:**

   - High-level `fs` helpers (read_text, write_text, mkdir) will be built on top of `stardos/io/file` FFI
   - User can choose between convenience functions or lower-level `IoDevice` API

2. **Process output capture:**

   - `run()` returns `ProcessOutput` with captured stdout/stderr
   - `spawn()` returns `ProcessHandle` with `IoDevice` pipes for streaming I/O

3. **Error types:**

   - Single unified `IoError` type for all I/O operations
   - Module-specific error types only for non-I/O concerns (e.g., `ParseError` in time parsing)

4. **Async handling:**
   - All Gleam APIs are synchronous (Result-returning)
   - Node.js async operations wrapped internally (blocking the event loop if needed)
   - Browser operations gracefully degrade where unsupported

---

## Testing Strategy

- **Unit tests:** Module-level tests in `test/stardos_*.gleam`
- **Integration tests:** Cross-module scenarios (spawn process, pipe I/O, check resource usage)
- **Cross-platform tests:** Same tests run on BEAM, Node, browser (with expected failures documented)
- **FFI verification:** Ensure FFI layer handles all error cases

---

## Blockers & Open Questions

1. **Gleam async/await:** Does Gleam have a plan for async/await syntax? Affects Node.js implementation.
2. **Browser support scope:** Which operations are realistic in a browser? Document graceful degradation.
3. **File descriptor passing:** Can `IoDevice` abstractions be extended to support IPC (Unix domain sockets, pipes)?
4. **Signal handling:** How should signal handlers integrate with Gleam's actor model (if at all)?

---

## Success Criteria

✅ **Completed:**

- API design for all 9+ modules (ENV, PROCESS, SIGNAL, OS, TIME, USER, RESOURCE, TERM, IO/DEVICE)
- Idiomatic Gleam style (Result(T, Nil) for queries, Result(T, IoError) for I/O)
- Cross-target compatibility documented (BEAM, Node, Browser)
- Module relationships and dependencies mapped

🔄 **In Progress:**

- (None; waiting for implementation phase)

⏳ **Pending:**

- FFI stubs for each target
- Gleam wrapper modules
- Tests and examples
- README and quickstart guide
