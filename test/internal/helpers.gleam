import stardos/env

pub fn runtime_flags() {
  case env.runtime() {
    env.Erlang(_) -> ["erlang"]
    env.JavaScript(js_runtime) -> {
      let js_flag = case js_runtime {
        env.Node(_) -> ["--runtime", "node"]
        env.Deno(_) -> ["--runtime", "deno"]
        env.Bun(_) -> ["--runtime", "bun"]
        env.Unknown -> []
      }
      ["javascript", ..js_flag]
    }
  }
}
