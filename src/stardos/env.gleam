//// The `env` module provides process-scoped environment
//// information and functionality, such as accessing
//// environment variables, command-line arguments, and
//// the current working directory.

import gleam/dict.{type Dict}
import gleam/result
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

/// Retrieves the home directory path for the current user.
/// TODO improve implementation to match Node's `os.homedir()`
pub fn home_dir() -> Result(String, Nil) {
  case os.platform() {
    os.Win32 -> var("USERPROFILE")
    _ -> var("HOME")
  }
}

/// Retrieves the path to the system's temporary directory.
/// TODO improve implementation to match Node's `os.tmpdir()`
pub fn temp_dir() -> String {
  let assert Ok(dir) = {
    use _ <- result.try_recover(var("TMPDIR"))
    use _ <- result.try_recover(var("TMP"))
    use _ <- result.try_recover(var("TEMP"))
    Ok("/tmp")
  }
  dir
}
