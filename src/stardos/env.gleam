//// The `env` module provides process-scoped environment
//// information and functionality, such as accessing
//// environment variables, command-line arguments, and
//// the current working directory.

import gleam/dict.{type Dict}

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

@external(javascript, "./env_ffi.mjs", "homeDir")
pub fn home_dir() -> Result(String, Nil)

@external(javascript, "./env_ffi.mjs", "tempDir")
pub fn temp_dir() -> String
