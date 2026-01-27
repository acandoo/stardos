//// The `argv` module allows the program to obtain the runtime being used, the program name
//// This module keeps API compatibility with the popular Gleam package `argv`.

import stardos/env

pub type Argv {
  Argv(runtime: String, program: String, arguments: List(String))
}

@deprecated("Use functions in stardos/env module instead.")
pub fn load() -> Argv {
  let runtime = case env.runtime() {
    env.Erlang(path) -> path
    env.JavaScript(js_runtime) ->
      case js_runtime {
        env.Node(path) -> path
        env.Deno(path) -> path
        env.Bun(path) -> path
        // Note: "browser" is used here for compatibility with the `argv` package.
        env.Unknown -> "browser"
      }
  }
  Argv(runtime:, program: env.program(), arguments: env.sub_args())
}
