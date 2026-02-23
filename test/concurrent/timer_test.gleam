import gleam/io
import gleam/list
import gleam/string
import internal/helpers
import shellout

pub fn main() {
  timer_test()
}

pub fn timer_test() -> Nil {
  let runtime_base_flag = helpers.runtime_flags()

  // In the future I'll have to figure out a better way to test
  // async code.

  // Later note to self: I realized from a different problem that
  // the timing issue is due to blocking operations like the sleep
  // test hogging up the event loop and putting all the timer tests
  // out of whack. This is not clear to the user, so I'll have to
  // figure out how to design async to prevent this from happening.

  // I still don't think I can put the tests back into timer_test,
  // since Promises are not returned directly from the test functions,
  // meaning that errors wouldn't be handled properly.

  // Maybe make Future-compatible test runner? I have to think about
  // Erlang, though, Futures there would be represented by PIDs, and
  // errors should be propagated properly, so maybe it's just a matter
  // of JavaScript.
  let assert Ok(message) =
    shellout.command(
      run: "gleam",
      with: [
        "run",
        "-m",
        "concurrent/timer/timer_main_fixture",
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
