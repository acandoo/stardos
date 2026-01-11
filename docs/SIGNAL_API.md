# Stardos Signal API — detailed design

This document specifies `stardos/signal`, the POSIX signal handling module.

**Error handling:** All operations return `Result(T, IoError)`. See `DESIGN_SUMMARY.md` for error type definition.

## Core principle

`stardos/signal` provides signal sending and (optionally) signal handling. Signals are asynchronous notifications to a process.

## Types

```gleam
pub type Signal {
  SigTerm   // Termination signal
  SigKill   // Kill signal (cannot be caught)
  SigInt    // Interrupt (Ctrl+C)
  SigHup    // Hangup
  SigUsr1   // User-defined 1
  SigUsr2   // User-defined 2
  SigWinch  // Window change (TTY)
  SigChld   // Child process state change
  SigPipe   // Broken pipe
  SigStop   // Stop (cannot be caught)
  SigCont   // Continue after stop
  Custom(Int) // Platform-specific signal number
}
/// POSIX signal types.

pub type SignalHandler {
  Default
  Ignore
  Handler(fn() -> Nil)
}
/// How to handle a signal.
```

## API

### `send` — send signal to process

```gleam
pub fn send(pid: Int, signal: Signal) -> Result(Nil, IoError)
```

Send a signal to a process by PID. Requires appropriate permissions.

**Notes:**

- `SigKill` and `SigStop` cannot be caught or ignored.
- Sending an invalid signal returns `Error`.

**Example:**

```gleam
import stardos/signal
import stardos/process

let pid = process.current_pid()
signal.send(pid, signal.SigUsr1) // send yourself a signal
```

### `set_handler` — set signal handler

```gleam
pub fn set_handler(signal: Signal, handler: SignalHandler) -> Result(Nil, IoError)
```

Install a signal handler for the current process. When the signal is received, the handler function is called asynchronously.

**Notes:**

- `SigKill` and `SigStop` cannot have handlers installed.
- Handler functions run in an async context; they should be simple and not block.
- On some platforms, signal handlers have limited capabilities (e.g., can't allocate memory).
- Returns `Error(io.Unsupported)` on platforms with no signal handling (e.g., browser, some JS runtimes).

**Example:**

```gleam
import stardos/signal

signal.set_handler(signal.SigInt, signal.Handler(fn() {
  io.println("Caught SIGINT, cleaning up...")
  // cleanup code
}))
```

### `ignore` — ignore a signal

```gleam
pub fn ignore(sig: Signal) -> Result(Nil, IoError)
```

Ignore a signal (install an ignore handler). Equivalent to `set_handler(sig, Ignore)`.

### `default` — restore default handler

```gleam
pub fn default(sig: Signal) -> Result(Nil, IoError)
```

Restore the default behavior for a signal. Equivalent to `set_handler(sig, Default)`.

### `signal_name` — get signal name

```gleam
pub fn signal_name(signal: Signal) -> String
```

Return a human-readable name for a signal (e.g., "SIGTERM", "SIGINT").

### `signal_from_number` — look up signal by number

```gleam
pub fn signal_from_number(num: Int) -> Option(Signal)
```

Convert a numeric signal number to a `Signal` variant. Returns `None` if the number is not a standard signal on this platform.

## Cross-target notes

| Function      | BEAM | Node | Browser |
| ------------- | ---- | ---- | ------- |
| `send`        | ✓    | ✓    | ❌      |
| `set_handler` | ✓    | ⚠️   | ❌      |
| `ignore`      | ✓    | ⚠️   | ❌      |
| `default`     | ✓    | ⚠️   | ❌      |
| `signal_name` | ✓    | ✓    | ✓       |

**Notes:**

- BEAM: full support for all signal operations.
- Node: limited support for signal handling (depends on platform). `send` works; `set_handler` may be restricted or require special setup.
- Browser: no signal support; all operations return `Error(io.Unsupported)`.

## Examples

### Graceful shutdown

```gleam
import stardos/signal
import stardos/io

pub fn setup_shutdown_handler() {
  signal.set_handler(signal.SigTerm, signal.Handler(fn() {
    io.println("Received SIGTERM, shutting down gracefully...")
    // trigger shutdown logic
    process.exit(0)
  }))
  signal.set_handler(signal.SigInt, signal.Handler(fn() {
    io.println("Received SIGINT, shutting down...")
    process.exit(0)
  }))
}
```

### Ignore broken pipe

```gleam
import stardos/signal

// Useful for programs that output to pipes that may close
signal.ignore(signal.SigPipe)
```

### Custom signal handling

```gleam
import stardos/signal

// Handler for user-defined signals
signal.set_handler(signal.SigUsr1, signal.Handler(fn() {
  // reload config, restart workers, etc.
  io.println("Reloading configuration...")
}))
```

## Summary

`stardos/signal` provides ergonomic signal sending and handling for process control and asynchronous notifications. It's designed for server-like applications that need graceful shutdown and dynamic reconfiguration. Prefer `stardos/process.kill()` for sending signals to child processes.
