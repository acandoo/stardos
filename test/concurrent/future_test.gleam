import gleam/io
import gleam/list
import gleam/string
import internal/helpers
import shellout

pub fn main() -> Nil {
  future_test()
}

pub fn future_test() -> Nil {
  let runtime_base_flag = helpers.runtime_flags()

  // In the future I'll have to figure out a better way to test
  // async code.
  let assert Ok(message) =
    shellout.command(
      run: "gleam",
      with: [
        "run",
        "-m",
        "concurrent/future/future_main_fixture",
        "-t",
        ..runtime_base_flag
      ],
      in: ".",
      opt: [],
    )

  message
  |> string.split("\n")
  |> list.drop(2)
  |> string.join("\n")
  |> io.println
}
