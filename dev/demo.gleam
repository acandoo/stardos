import gleam/bit_array
import gleam/list
import stardos/concurrent/future
import stardos/concurrent/task
import stardos/env.{type JavascriptRuntime}
import stardos/io
import stardos/io/file
import stardos/io/path

pub fn main() -> Nil {
  task.spawn(async_main())
  Nil
}

fn async_main() -> future.Future(Nil) {
  let args = env.sub_args()
  let runtime = env.runtime()
  case runtime {
    env.Erlang(path) ->
      io.println("You are running on Erlang (" <> path <> ")!")
    env.Javascript(js_runtime) ->
      io.println(
        "You are running on JavaScript with the "
        <> js_runtime_to_string(js_runtime)
        <> "runtime!",
      )
  }
  let reads = args |> list.map(fn(file) { file.read(path.absolute(file)) })
  use results <- future.await(future.all(reads))
  let data =
    results
    |> list.filter_map(fn(result) {
      case result {
        Ok(data) -> Ok(data)
        Error(_) -> {
          io.println_error("Unable to read one of the files.")
          Error(Nil)
        }
      }
    })
  let assert Ok(concat) = bit_array.concat(data) |> bit_array.to_string
  io.println(concat)
  future.resolve(Nil)
}

fn js_runtime_to_string(runtime: JavascriptRuntime) -> String {
  case runtime {
    env.Node(path) -> "Node (" <> path <> ")"
    env.Deno(path) -> "Deno (" <> path <> ")"
    env.Bun(path) -> "Bun (" <> path <> ")"
    env.Unknown -> "unknown"
  }
}
