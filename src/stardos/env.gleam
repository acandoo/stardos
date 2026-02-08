//// The `env` module provides process-scoped environment
//// information and functionality, such as accessing
//// environment variables, command-line arguments, and
//// the current working directory.

import gleam/dict.{type Dict}
import gleam/result
import gleam/string
import stardos/os

pub type Runtime {
  Erlang(path: String)
  JavaScript(runtime: JavaScriptRuntime)
}

pub type JavaScriptRuntime {
  Node(path: String)
  Deno(path: String)
  Bun(path: String)
  Unknown
}

/// Retrieves runtime information for the current environment,
/// including when available a path to the runtime executable.
/// 
/// ## Examples
/// 
/// Check if the runtime is Erlang or JavaScript:
/// 
/// ```gleam
/// let runtime = runtime()
/// case runtime {
///   Erlang(_) -> todo as "handle erlang runtime"
///   JavaScript(_) -> todo as "handle javascript runtime"
/// }
/// ```
/// 
@external(javascript, "./env_ffi.mjs", "runtime")
pub fn runtime() -> Runtime

/// Retrieves the program name or path used to invoke the current process.
/// 
/// ## Examples
/// 
/// Program is at a specific module path:
/// 
/// ```gleam
/// let program_name = program()
/// // -> "/home/lucy/.local/bin/my_program.mjs"
/// ```
/// 
/// Program is an executable, say, with `#!/usr/bin/env node`:
/// 
/// ```gleam
/// let program_name = program()
/// // -> "/home/lucy/.local/bin/my_program"
/// ```
///
@external(javascript, "./env_ffi.mjs", "program")
pub fn program() -> String

@external(javascript, "./env_ffi.mjs", "args")
pub fn args() -> List(String)

@external(javascript, "./env_ffi.mjs", "subArgs")
pub fn sub_args() -> List(String)

@external(javascript, "./env_ffi.mjs", "getVar")
pub fn var(var: String) -> Result(String, Nil)

@external(javascript, "./env_ffi.mjs", "setVar")
pub fn set_var(var: String, value: String) -> Nil

@external(javascript, "./env_ffi.mjs", "getVars")
pub fn vars() -> Dict(String, String)

@external(javascript, "./env_ffi.mjs", "removeVar")
pub fn remove_var(var: String) -> Nil

@external(javascript, "./env_ffi.mjs", "cwd")
pub fn cwd() -> Result(String, Nil)

@external(javascript, "./env_ffi.mjs", "setCwd")
pub fn set_cwd(path: String) -> Result(Nil, Nil)

// Although it looks weird, returning a Result for
// home_dir but not for temp_dir has precedent
// when compared to other languages. See Rust's std::env module for example:
// https://doc.rust-lang.org/std/env/fn.home_dir.html

/// Retrieves the home directory path for the current user.
@external(javascript, "./env_ffi.mjs", "homeDir")
pub fn home_dir() -> Result(String, Nil) {
  case os.platform() {
    os.Win32 -> var("USERPROFILE")
    _ -> var("HOME")
  }
}

/// Retrieves the path to the system's temporary directory.
@external(javascript, "./env_ffi.mjs", "tempDir")
pub fn temp_dir() -> String {
  let path = case os.platform() {
    os.Win32 -> {
      // This maintains logic parity with Node's `os.tmpdir()` implementation on Windows,
      // which checks the `TEMP`, `TMP`, `SystemRoot`, and `windir` environment variables in that order,
      // and falls back to a system temp directory if none of those are set.
      use <- result.lazy_unwrap(var("TEMP"))
      use <- result.lazy_unwrap(var("TMP"))
      let system_root = {
        use <- result.lazy_unwrap(var("SystemRoot"))
        use <- result.lazy_unwrap(var("windir"))
        // This is *technically* not at parity with Node's implementation,
        // but it would fall back to "undefined\\temp" in the absence of both `SystemRoot` and `windir`,
        // which I don't think is worth replicating.
        ""
      }

      system_root <> "\\temp"
    }
    _ -> {
      use <- result.lazy_unwrap(var("TMPDIR"))
      use <- result.lazy_unwrap(var("TMP"))
      use <- result.lazy_unwrap(var("TEMP"))
      "/tmp"
    }
  }
  case
    string.length(path) > 1
    && string.ends_with(path, "\\")
    && !string.ends_with(path, ":\\")
  {
    True -> string.drop_end(path, 1)
    False -> path
  }
}
