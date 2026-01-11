# Stardos API proposal — batteries-included OS library

Goals

- Provide one ergonomic, high-level way to perform common OS tasks (files, env, processes, args).
- Keep a small, consistent surface: `fs`, `env`, `process`, `argv`, `io`.
- Offer both a simple blocking/result-style API for ergonomics and a lower-level callback/FFI surface for advanced cases and platform interop.

Current status (summary)

- `src/stardos/io/file.gleam` exposes callback-based `at_path`, `open`, `new`, `read`, `write`.
- `src/stardos/argv.gleam` exposes `load()` using FFI.
- `src/stardos/env.gleam`, `os.gleam`, and `process.gleam` are largely empty/placeholders.

Problems / opportunities

- The callback style across `file` is explicit but noisy for most callers. Many languages provide promise/Result-first ergonomics.
- There is duplication risk (many small helpers) unless we define a canonical, high-level API that most code will use.
- Target differences (Erlang vs JavaScript) mean we should keep a thin FFI layer and offer a unified ergonomic wrapper above it.

High-level proposal

1. Design principles

- One clear, high-level API per domain that is idiomatic and simple to use.
- Return `Result(T, IoError)` for fallible operations — call sites pattern-match once and handle errors clearly.
- Provide synchronous-style wrappers in Gleam that hide FFI callbacks where possible (internally implemented with target-specific FFI that blocks or uses promises under the hood).
- Keep lower-level async/callback FFI available for advanced use and streaming.

2. Modules and surface

- `stardos/fs` (or `stardos/file`): path-based convenience functions and a minimal `File` handle.
- `stardos/env`: `get`, `set`, `remove`, `vars()`.
- `stardos/process`: `run`, `spawn`, `exit_code` helpers, and `ProcessOutput` capturing stdout/stderr.
- `stardos/argv`: keep `load()` as-is.
- `stardos/io`: console helpers (println), re-export `IoError`.

3. Example API signatures (suggested Gleam)

fs module (high-level convenience)

pub type IoError = ...

pub fn read_text(path: String) -> Result(String, IoError)
pub fn write_text(path: String, contents: String) -> Result(Nil, IoError)
pub fn read_bytes(path: String) -> Result(BitArray, IoError)
pub fn write_bytes(path: String, data: BitArray) -> Result(Nil, IoError)
pub fn exists(path: String) -> Bool
pub fn remove(path: String) -> Result(Nil, IoError)
pub fn rename(from: String, to: String) -> Result(Nil, IoError)
pub fn create_dir(path: String) -> Result(Nil, IoError)
pub fn read_dir(path: String) -> Result(List(String), IoError)

Process module

pub type ProcessOutput { ProcessOutput(stdout: BitArray, stderr: BitArray, code: Int) }

pub fn run(cmd: String, args: List(String)) -> Result(ProcessOutput, IoError)
pub fn spawn(cmd: String, args: List(String)) -> Result(ProcessId, IoError)

Env module

pub fn get(key: String) -> Option(String)
pub fn set(key: String, value: String) -> Result(Nil, IoError)
pub fn remove(key: String) -> Result(Nil, IoError)
pub fn vars() -> List(#(String, String))

Notes on ergonomics

- Prefer `read_text`/`write_text` for the common case of small files and configuration.
- Offer lower-level `open`, `read`, `write` with `FileHandle` for streaming or large files — these may retain a callback or streaming API.
- Provide both `read_text` and `read_text_safe` variants if needed (the latter returns Option or default). Keep names simple.

Compatibility and implementation notes

- Keep current `file.*` callback FFI functions as the thin portability layer (they already exist for JS). Implement ergonomic wrappers in Gleam that call those FFI functions and return `Result`.
- For Erlang BEAM target, the FFI can map to synchronous calls, so the wrapper can become truly synchronous; for JS target, the wrapper can await a Promise or use a synchronous-looking API implemented with a runtime-managed task.
- Document which functions are synchronous vs async for each target. Where full sync semantics are impossible for JS, make the wrapper still present a `Result` synchronously by performing the operation at native package build time or by returning a `Result(Promise(...))` type if unavoidable — but prefer to hide complexity and keep the high-level API consistent across targets by implementing promises inside the wrapper.

Cross-language references (for design inspiration)

- Rust: `std::fs::read_to_string`, `std::fs::write`, `std::process::Command` (clear, blocking Result-first API).
- Python: `pathlib.Path.read_text()` and `subprocess.run` (batteries-included, high-level helpers).
- Node: `fs/promises` (Promise-based) and `child_process.exec` (multiple modes). Use its `fs/promises` ergonomics as inspiration for JS target wrappers.
- Go: `ioutil.ReadFile`, `os/exec` — simple blocking helpers that return error values.

Migration path and compatibility

- Phase 1: Keep FFI functions as-is. Add `stardos/fs.gleam` wrappers implementing the high-level functions using the existing callback FFI.
- Phase 2: Implement small BEAM-side native support (if needed) to make the high-level wrappers true blocking `Result` returners for Erlang target.
- Phase 3: Add docs and examples, plus tests under `test/` demonstrating idiomatic usage.

Examples

Reading a config file (recommended)

```gleam
import stardos/fs

pub fn load_config(path: String) -> Result(Config, String) {
  case fs.read_text(path) {
    Ok(contents) -> Ok(parse_config(contents))
    Error(e) -> Error("Unable to read config: " <> io_error.to_string(e))
  }
}
```

Running a command and checking exit code

```gleam
import stardos/process

let result = process.run("git", ["status"]) // returns Result(ProcessOutput, IoError)
```

Next steps (concrete)

- Implement `stardos/fs.gleam` wrappers that call existing `stardos/io/file` FFI functions and return `Result`.
- Fill out `src/stardos/env.gleam` and `src/stardos/process.gleam` with the high-level APIs above and thin FFI bindings.
- Add examples to `test/stardos_test.gleam` demonstrating the new high-level API.
- Write docs: update [README.md](README.md) with a short quickstart and link to `docs/API_PROPOSAL.md`.

Appendix: recommended minimal first-implementation tasks

- Add `stardos/fs.gleam` with `read_text`, `write_text`, `exists`, `remove`, `read_dir` implemented atop `stardos/io/file`.
- Add `stardos/process.gleam` FFI for `run` (capture stdout/stderr) and small wrapper.
- Document differences between targets in `docs/targets.md`.

End of proposal
