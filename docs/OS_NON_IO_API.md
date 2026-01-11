# Stardos — Non‑I/O OS API draft

This document sketches a concise, ergonomic API for OS features that are not primarily about filesystem or socket I/O. The goal is one clear way to do common OS tasks: environment, process lifecycle, system info, time, users, signals, and resource inspection.

Design principles

- Prefer simple, blocking `Result(T, IoError)`-style functions at the Gleam API level (call sites pattern-match once). The thin FFI layer may remain callback/promise-based per target.
- Keep small, focused modules: `env`, `process`, `os`, `time`, `user`, `signal`, `resource`, and `term`.
- Provide helpers for common workflows (run a command, get cwd, read env var with default).

Modules & API

1. `stardos/env`

- Purpose: environment variables and working directory helpers.

Signatures

pub fn get(key: String) -> Option(String)
pub fn get_or(key: String, default: String) -> String
pub fn set(key: String, value: String) -> Result(Nil, IoError)
pub fn remove(key: String) -> Result(Nil, IoError)
pub fn vars() -> List(#(String, String))
pub fn cwd() -> Result(String, IoError)
pub fn chdir(path: String) -> Result(Nil, IoError)
pub fn home_dir() -> Option(String)
pub fn temp_dir() -> String

Notes: `temp_dir()` returns a platform-appropriate path (never fails). `cwd()`/`chdir()` affect current process only.

2. `stardos/process`

- Purpose: run and manage child processes.

Types

pub type ProcessOutput { ProcessOutput(stdout: BitArray, stderr: BitArray, code: Int) }
pub type ProcessHandle

Signatures

pub fn run(cmd: String, args: List(String), given env: Option(List(#(String,String))), given cwd: Option(String)) -> Result(ProcessOutput, IoError)
pub fn spawn(cmd: String, args: List(String), given env: Option(List(#(String,String))), given cwd: Option(String)) -> Result(ProcessHandle, IoError)
pub fn wait(handle: ProcessHandle) -> Result(Int, IoError) // exit code
pub fn kill(handle: ProcessHandle, signal: Signal) -> Result(Nil, IoError)
pub fn try_wait(handle: ProcessHandle) -> Option(Result(Int, IoError))
pub fn detached_run(cmd: String, args: List(String)) -> Result(Nil, IoError)

Notes: `run` is a convenience that captures stdout/stderr fully (useful for simple CLI calls). `spawn` returns a handle for streaming I/O (see `io_device` in other docs). `detached_run` starts a background process detached from caller.

3. `stardos/os` (system info)

- Purpose: non-process, non-file system information about the host.

Types

pub type Platform { Linux | MacOS | Windows | Unknown }

Signatures

pub fn platform() -> Platform
pub fn arch() -> String // e.g. "x86_64", "arm64"
pub fn hostname() -> Result(String, IoError)
pub fn uptime() -> Result(Float, IoError) // seconds
pub fn load_average() -> Result(#(Float, Float, Float), IoError)
pub fn num_cpus() -> Int

4. `stardos/time`

- Purpose: time helpers and timezone info.

Types

pub type SystemTime { SystemTime(Int) } // seconds since epoch, or use Int/Float as needed

Signatures

pub fn now() -> SystemTime
pub fn now_unix() -> Int
pub fn monotonic() -> Float // high-resolution monotonic clock seconds
pub fn timezone() -> Result(String, IoError)
pub fn sleep(seconds: Float) -> Nil

5. `stardos/user`

- Purpose: user and group info where available.

Types

pub type UserInfo { UserInfo(name: String, uid: Option(Int), gid: Option(Int), home: Option(String)) }

Signatures

pub fn current_user() -> Option(UserInfo)
pub fn lookup_user(name: String) -> Option(UserInfo)

Notes: On platforms where uid/gid are unavailable (e.g., some JS runtimes), fields should be `Option`.

6. `stardos/signal`

- Purpose: process signal names and handling.

Types

pub type Signal { SigInt | SigTerm | SigKill | SigUsr1 | SigUsr2 | SigWinch | Other(Int) }

Signatures

pub fn send(pid: Int, signal: Signal) -> Result(Nil, IoError)
pub fn set_handler(signal: Signal, handler: fn() -> Nil) -> Result(Nil, IoError)

Notes: `set_handler` must document which signals are supported per target; on limited targets it returns `Error(io.Unsupported)`.

7. `stardos/resource`

- Purpose: inspect process resource usage (memory/CPU/time).

Types

pub type ResourceUsage { cpu_seconds: Float, memory_bytes: Int }

Signatures

pub fn current_usage() -> Result(ResourceUsage, IoError)

8. `stardos/term`

- Purpose: terminal capabilities and TTY detection.

Signatures

pub fn isatty(fd: Int) -> Bool
pub fn terminal_size() -> Option(#(Int, Int)) // columns, rows

Cross-target considerations

- BEAM/Erlang: many syscalls can be implemented synchronously; signal handling and process spawning map directly to Erlang primitives. Prefer idiomatic BEAM implementations.
- JavaScript (Node): many operations are inherently async; provide Gleam wrappers that either block via runtime helpers or return results by awaiting Promises internally. If blocking is impossible, document that the function returns a `Result` synchronously but may internally schedule async work — keep API shape stable.
- Browser: limited OS features; functions should return `Error(io.Unsupported)` or `Option` where appropriate.

Examples

Read env with default

```gleam
import stardos/env

let port = env.get_or("PORT", "8080")
```

Run command and check exit code

```gleam
import stardos/process

case process.run("git", ["status"], given: None, given: None) {
  Ok(output) -> // inspect output.stdout/stderr
  Error(e) -> // handle
}
```

Next steps

- Review these signatures and confirm naming conventions and error models (`IoError` reuse vs specific error types).
- Implement thin FFI functions for missing primitives per target and add Gleam wrappers in `src/stardos/` modules.
- Add tests under `test/` demonstrating common use-cases.

End of draft
