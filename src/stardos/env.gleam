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

/// Retrieves the command-line arguments passed to the current process.
/// 
/// ## Example
/// 
/// Given a program invoked by Node with `node my_program.mjs arg1 arg2`:
/// 
/// ```gleam
/// let arguments = args()
/// // -> ["/home/lucy/.local/bin/node", "/home/lucy/.local/bin/my_program.mjs", "arg1", "arg2"]
/// ```
/// 
@external(javascript, "./env_ffi.mjs", "args")
pub fn args() -> List(String)

/// Retrieves the command-line arguments passed to the current process,
/// excluding the program name and runtime.
/// 
/// ## Example
/// 
/// Given a program invoked by Node with `node my_program.mjs arg1 arg2`:
/// 
/// ```gleam
/// let sub_arguments = sub_args()
/// // -> ["arg1", "arg2"]
/// ```
///
@external(javascript, "./env_ffi.mjs", "subArgs")
pub fn sub_args() -> List(String)

/// Retrieves the environment variable with the given name, if it exists.
/// 
/// ## Examples
/// 
/// Given an environment variable `MY_VAR` with value `hello`:
/// 
/// ```gleam
/// let my_var = var("MY_VAR")
/// // -> Ok("hello")
/// ```
/// 
/// Given an environment variable `MY_VAR` that is not set:
/// 
/// ```gleam
/// let my_var = var("MY_VAR")
/// // -> Err(Nil)
/// ```
///
@external(javascript, "./env_ffi.mjs", "getVar")
pub fn var(var: String) -> Result(String, Nil)

/// Sets an environment variable with the given name and value.
/// 
/// ## Examples
/// 
/// Set an environment variable `MY_VAR` to `hello`:
/// 
/// ```gleam
/// set_var("MY_VAR", "hello")
/// // -> Ok(Nil)
/// ```
/// 
/// After setting, retrieving `MY_VAR` will yield the new value:
/// 
/// ```gleam
/// let my_var = var("MY_VAR")
/// // -> Ok("hello")
/// ```
///
@external(javascript, "./env_ffi.mjs", "setVar")
pub fn set_var(var: String, value: String) -> Nil

/// Retrieves a dictionary of all environment variables and their values.
/// 
/// ## Example
///
/// Given environment variables `MY_VAR1=hello` and `MY_VAR2=world`:
/// 
/// ```gleam
/// let env_vars = vars()
/// // -> dict.from_list([#("MY_VAR1", "hello"), #("MY_VAR2", "world")])
/// ```
/// 
@external(javascript, "./env_ffi.mjs", "getVars")
pub fn vars() -> Dict(String, String)

/// Removes the environment variable with the given name.
/// 
/// ## Examples
/// 
/// Given an environment variable `MY_VAR` that is set:
/// 
/// ```gleam
/// remove_var("MY_VAR")
/// // -> Nil
/// 
/// let my_var = var("MY_VAR")
/// // -> Err(Nil)
/// ```
/// 
/// Given an already unset environment variable `MY_VAR`:
/// 
/// ```gleam
/// remove_var("MY_VAR")
/// // -> Nil
/// ```
/// 
@external(javascript, "./env_ffi.mjs", "removeVar")
pub fn remove_var(var: String) -> Nil

/// Retrieves the current working directory of the process.
/// 
/// ## Example
/// 
/// Given the current working directory is `/home/lucy/projects/my_app`:
/// 
/// ```gleam
/// let current_dir = cwd()
/// // -> Ok("/home/lucy/projects/my_app")
/// ```
///
@external(javascript, "./env_ffi.mjs", "cwd")
pub fn cwd() -> Result(String, Nil)

/// Changes the current working directory of the process to the specified path.
/// 
/// ## Examples
/// 
/// Change the current working directory to `/home/lucy`:
/// 
/// ```gleam
/// set_cwd("/home/lucy")
/// // -> Ok(Nil)
/// ```
/// 
/// Ensure the current working directory has been updated:
/// 
/// ```gleam
/// let assert Ok(_) = set_cwd("/home/lucy")
/// let current_dir = cwd()
/// // -> Ok("/home/lucy")
/// ```
///
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
