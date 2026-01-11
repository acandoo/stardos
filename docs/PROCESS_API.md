# Stardos Process API — detailed design

This document specifies the `stardos/process` module for spawning, managing, and communicating with child processes.

**Error handling:** All fallible operations return `Result(T, IoError)`. See `DESIGN_SUMMARY.md` for the unified error type definition.

## Core design principles

- **Simplicity first**: `run()` for simple "execute and wait" use-cases; `spawn()` for fine-grained control and streaming I/O.
- **IoDevice integration**: Process streams (stdin/stdout/stderr) are `IoDevice` instances, enabling generic piping.
- **Result-first API**: All fallible operations return `Result(T, IoError)` at the Gleam level.
- **Cross-target**: Stable API across BEAM (sync), Node (async-wrapped), browser (unsupported).

## Types

```gleam
pub type ProcessHandle
/// Opaque handle to a running child process.
/// Allows querying status, sending signals, or waiting for exit.

pub type ProcessOutput {
  ProcessOutput(
    stdout: BitArray,
    stderr: BitArray,
    exit_code: Int,
  )
}
/// Captured output and exit code from a completed process.

pub type ProcessId = Int
/// Platform-specific process ID (PID).

pub type Signal = stardos/signal.Signal
/// See `stardos/signal` module for signal type definition.

pub type Stdio {
  Inherit    // Use parent's streams
  Piped      // Capture via IoDevice
  Null       // Discard
  File(String) // Redirect to/from file
}
/// How to configure process stdin/stdout/stderr.
```

## High-level API

### `run` — spawn and wait, capturing output

```gleam
pub fn run(
  cmd: String,
  args: List(String),
) -> Result(ProcessOutput, IoError)
```

Convenience function: spawn a process, wait for completion, and return captured stdout/stderr + exit code. Equivalent to:

```gleam
run("git", ["status"])
// => Result(ProcessOutput(...), IoError)
```

**Notes:**

- Both stdout and stderr are captured as `BitArray`.
- Blocks until process exits.
- Use `spawn()` if you need streaming I/O or control over the child.
- On JS (Node), this internally awaits the process completion.

### `spawn` — spawn without waiting

```gleam
pub fn spawn(
  cmd: String,
  args: List(String),
  given env: Option(List(#(String, String))),
  given cwd: Option(String),
  given stdin: Stdio,
  given stdout: Stdio,
  given stderr: Stdio,
) -> Result(ProcessHandle, IoError)
```

Spawn a child process and return a handle. Caller is responsible for managing the process lifetime.

**Parameters:**

- `cmd`: executable name or path.
- `args`: command-line arguments.
- `env`: environment variables for child (inherits parent's if `None`).
- `cwd`: working directory for child (inherits parent's if `None`).
- `stdin`, `stdout`, `stderr`: how to configure each stream (see `Stdio` type above).

**Returns:** `ProcessHandle` for further operations (wait, kill, query).

**Example:**

```gleam
use handle <- spawn(
  "bash",
  ["-c", "echo hello; sleep 10"],
  given: None,
  given: None,
  given: Piped,
  given: Piped,
  given: Piped,
)
// => ProcessHandle
```

### `wait` — wait for process exit

```gleam
pub fn wait(handle: ProcessHandle) -> Result(ProcessOutput, IoError)
```

Block until the process exits and return captured output + exit code.

**Notes:**

- Only works if `stdout` and `stderr` were configured as `Piped` during `spawn()`.
- If streams were `Inherit`, stdout/stderr will be empty in the result.
- If streams were `Null` or `File(...)`, those sections are empty.

### `wait_with_timeout` — wait with timeout

```gleam
pub fn wait_with_timeout(
  handle: ProcessHandle,
  timeout_seconds: Float,
) -> Result(Option(ProcessOutput), IoError)
```

Wait up to `timeout_seconds` for the process to exit.

**Returns:**

- `Ok(Some(ProcessOutput))` if process exited before timeout.
- `Ok(None)` if timeout elapsed and process is still running.
- `Error(...)` if a system error occurred.

**Note:** Process continues running if timeout elapses; use `kill()` to terminate it.

### `try_wait` — non-blocking exit check

```gleam
pub fn try_wait(handle: ProcessHandle) -> Result(Option(ProcessOutput), IoError)
```

Check if process has exited without blocking.

**Returns:**

- `Ok(Some(ProcessOutput))` if the process has exited.
- `Ok(None)` if the process is still running.
- `Error(...)` if a system error occurred.

### `pid` — get process ID

```gleam
pub fn pid(handle: ProcessHandle) -> ProcessId
```

Return the platform-specific process ID (PID).

### `kill` — send signal to process

```gleam
pub fn kill(
  handle: ProcessHandle,
  signal: Signal,
) -> Result(Nil, IoError)
```

Send a POSIX signal to the process (e.g., `SigTerm` for graceful shutdown, `SigKill` for immediate termination).

**Notes:**

- On Windows, only `SigTerm` and `SigKill` are typically supported; others may error.
- Sending `SigKill` is forceful and may leave resources dangling; prefer `SigTerm` when possible.

### `stdin_device` — get writable IoDevice for stdin

```gleam
pub fn stdin_device(handle: ProcessHandle) -> Result(IoDevice, IoError)
```

Return an `IoDevice` for writing to the process's stdin. Only available if `stdin: Piped` was used during `spawn()`.

### `stdout_device` — get readable IoDevice for stdout

```gleam
pub fn stdout_device(handle: ProcessHandle) -> Result(IoDevice, IoError)
```

Return an `IoDevice` for reading from the process's stdout. Only available if `stdout: Piped` was used during `spawn()`.

### `stderr_device` — get readable IoDevice for stderr

```gleam
pub fn stderr_device(handle: ProcessHandle) -> Result(IoDevice, IoError)
```

Return an `IoDevice` for reading from the process's stderr. Only available if `stderr: Piped` was used during `spawn()`.

## Lower-level and utility APIs

### `current_pid` — get current process ID

```gleam
pub fn current_pid() -> ProcessId
```

Return the PID of the current process.

### `current_ppid` — get parent process ID

```gleam
pub fn current_ppid() -> Option(ProcessId)
```

Return the parent process ID if available (all Unix-like systems, Windows). Returns `None` if unsupported (rare).

### `exit` — terminate current process

```gleam
pub fn exit(code: Int) -> !
```

Exit the current process with the given exit code. Never returns (type `!`).

### `detached` — spawn detached process

```gleam
pub fn detached(
  cmd: String,
  args: List(String),
  given env: Option(List(#(String, String))),
  given cwd: Option(String),
) -> Result(ProcessId, IoError)
```

Spawn a child process that is detached from the parent (i.e., runs independently even if parent exits). Useful for background daemons.

**Returns:** The child's PID (no handle, since we don't wait for it).

## Convenience wrappers

### `run_simple` — run with no env/cwd customization

```gleam
pub fn run_simple(cmd: String, args: List(String)) -> Result(ProcessOutput, IoError)
```

Alias for `run()` without the extra parameters.

### `run_shell` — run a shell command string

```gleam
pub fn run_shell(shell_command: String) -> Result(ProcessOutput, IoError)
```

Execute a command string via the system shell (e.g., `/bin/sh -c` on Unix, `cmd.exe /c` on Windows).

**Example:**

```gleam
run_shell("ls -la | grep .txt")
```

**Note:** Avoid using with untrusted input (shell injection risk). Prefer structured `run()` where possible.

## Cross-target notes

| Feature            | BEAM/Erlang  | Node.js                   | Browser         |
| ------------------ | ------------ | ------------------------- | --------------- |
| `run`              | Sync         | Async (wrapped as Result) | ❌              |
| `spawn`            | Sync         | Async (wrapped)           | ❌              |
| `wait`             | Blocking     | Async (wrapped)           | ❌              |
| `try_wait`         | Non-blocking | Non-blocking              | ❌              |
| `kill`             | ✓            | ✓                         | ❌              |
| `exit`             | ✓            | ✓                         | ⚠️ (restricted) |
| Piped I/O          | ✓            | ✓                         | ❌              |
| Detached processes | ✓            | ✓                         | ❌              |

**Notes:**

- **BEAM**: All functions are synchronous (map to Erlang `os:cmd`, `erlang:open_port`, etc.).
- **Node**: Async operations are wrapped by `stardos` to return `Result` synchronously at the Gleam API level (internally awaiting Promises).
- **Browser**: Process APIs return `Error(io.Unsupported)`. Spawn/run are not available.

## Error handling

All functions return `Result(T, IoError)`. Common errors:

- `io.CommandNotFound` — executable not found in PATH.
- `io.PermissionDenied` — insufficient permissions to run command.
- `io.TimedOut` — operation exceeded timeout (for `wait_with_timeout`).
- `io.Unsupported` — platform or runtime does not support this operation (e.g., browser).
- `io.SystemError(msg)` — generic OS-level error.

## Examples

### Capture command output

```gleam
import stardos/process

case process.run("git", ["status"]) {
  Ok(output) -> {
    let code = output.exit_code
    let out_str = bit_array.to_string(output.stdout)
    io.println("Exit code: " <> int.to_string(code))
  }
  Error(e) -> io.println("Failed to run git")
}
```

### Spawn and pipe stdout to parent

```gleam
import stardos/process
import stardos/io

use handle <- process.spawn(
  "ls",
  ["-la"],
  given: None,
  given: None,
  given: Inherit,
  given: Piped,
  given: Inherit,
)
case process.stdout_device(handle) {
  Ok(child_out) -> {
    io.copy(child_out, io.stdout())
    let _ = process.wait(handle)
    Nil
  }
  Error(e) -> io.println("Failed to get stdout device")
}
```

### Run with custom environment

```gleam
import stardos/process

let custom_env = [#("MY_VAR", "my_value")]
case process.spawn(
  "env",
  [],
  given: Some(custom_env),
  given: None,
  given: Inherit,
  given: Piped,
  given: Inherit,
) {
  Ok(handle) -> {
    let _ = process.wait(handle)
    Nil
  }
  Error(e) -> io.println("Failed to spawn")
}
```

### Run shell command

```gleam
import stardos/process

case process.run_shell("echo 'Hello' && sleep 1") {
  Ok(output) -> io.println("Done")
  Error(e) -> io.println("Error")
}
```

## Design rationale & future extensions

### Why separate `run` and `spawn`?

- `run` is the 80% case: you want to execute a command, wait, and inspect the output. Simple API.
- `spawn` covers streaming I/O, long-running services, and process control. More powerful but requires explicit lifecycle management.

### Why `Stdio` type instead of separate functions?

- It mirrors Rust's `std::process::Stdio` and Go's `os/exec` design.
- It provides flexibility (inherit, pipe, null, redirect) in one place.
- It keeps the function signature clean while remaining extensible.

### Future considerations

- **Process groups / job control**: May add `process_group()`, `set_foreground()` if demand arises.
- **Async/streaming**: Current Gleam API is synchronous at the callsite (awaiting internally on Node). If full async is desired, could add `stardos/process/async` submodule later.
- **PTY support**: Pseudoterminal allocation for interactive processes (e.g., `ssh`, `less`). Could be in `stardos/process/pty`.
- **Signals**: Full signal handling (set handlers, masks) might be in `stardos/signal` module.

## Summary

The process module provides:

1. Simple `run()` for most CLI use-cases.
2. Powerful `spawn()` + device-based I/O for streaming and long-running processes.
3. Low-level utilities (pid, kill, exit) for fine-grained control.
4. Consistent, ergonomic API across targets (BEAM, Node, browser) via Result-first design.
