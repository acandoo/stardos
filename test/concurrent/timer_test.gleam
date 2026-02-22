import gleam/time/duration.{type Duration}
import gleam/time/timestamp
import shellout
import stardos/concurrent/future.{type Future}
import stardos/concurrent/task
import stardos/concurrent/timer
import stardos/env

// Accounts for overhead of spawning a process
const shell_tolerance_ms = 100

const upper_tolerance_ms = 10

const lower_tolerance_ms = 5

// timer.sleep tests

pub fn timer_sleep_tolerance_test() -> Nil {
  let first = timestamp.system_time()
  timer.sleep(duration.milliseconds(100))
  let elapsed_ms =
    timestamp.system_time()
    |> timestamp.difference(first, _)
    |> duration.to_milliseconds
  // The fixture waits for 100ms, so we check that at least that much time has elapsed, allowing some tolerance for scheduling delays

  assert { elapsed_ms + lower_tolerance_ms >= 100 }
    && { elapsed_ms <= 100 + upper_tolerance_ms }
    as "Elapsed time should be within tolerance"
}

// timer.timeout tests

pub fn timer_timeout_lifetime_test() -> Nil {
  let runtime_base_flag = case env.runtime() {
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

  let first = timestamp.system_time()
  let assert Ok(_) =
    shellout.command(
      run: "gleam",
      with: [
        "run",
        "-m",
        "concurrent/timer/timer_timeout_lifetime_fixture",
        "-t",
        ..runtime_base_flag
      ],
      in: ".",
      opt: [],
    )
  let elapsed_ms =
    timestamp.system_time()
    |> timestamp.difference(first, _)
    |> duration.to_milliseconds
  // The fixture waits for 1000ms, so we check that at least that much time has elapsed, allowing some tolerance for scheduling delays

  assert { elapsed_ms + lower_tolerance_ms >= 1000 }
    && { elapsed_ms <= 1000 + upper_tolerance_ms + shell_tolerance_ms }
    as "Elapsed time should be within tolerance"
}

// Don't trust `gleam test` for now since assertions seem to be buggy when combined with Promises

pub fn timer_timeout_tolerance_test() -> Nil {
  task.spawn(async_timer_timeout_tolerance_test(duration.milliseconds(100)))
  task.spawn(async_timer_timeout_tolerance_test(duration.milliseconds(500)))
  task.spawn(async_timer_timeout_tolerance_test(duration.milliseconds(1000)))
  Nil
}

fn async_timer_timeout_tolerance_test(duration: Duration) -> Future(Nil) {
  let first = timestamp.system_time()
  let duration_ms = duration.to_milliseconds(duration)

  use _ <- future.await(timer.timeout(duration))
  let elapsed_ms =
    timestamp.system_time()
    |> timestamp.difference(first, _)
    |> duration.to_milliseconds

  // Allow some tolerance for scheduling delays
  // Also, for some reason this needs brackets?
  assert { elapsed_ms + lower_tolerance_ms >= duration_ms }
    && { elapsed_ms <= duration_ms + upper_tolerance_ms }
    as "Elapsed time should be within tolerance"
  future.resolve(Nil)
}

pub fn timer_timeout_abort_test() -> Nil {
  task.spawn(async_timer_timeout_abort_test())
  Nil
}

fn async_timer_timeout_abort_test() -> Future(Nil) {
  let timeout_future = {
    use _ <- future.await(timer.timeout(duration.milliseconds(50)))
    panic as "Timer should have been aborted (synchronous abortion)"
  }

  let timeout_future_2 = {
    use _ <- future.await(timer.timeout(duration.milliseconds(500)))
    panic as "Timer should have been aborted (async abortion)"
  }

  let assert Ok(handle) = task.spawn_abortable(timeout_future)
  let assert Ok(handle_2) = task.spawn_abortable(timeout_future_2)
  task.abort(handle)
  use _ <- future.await(timer.timeout(duration.milliseconds(100)))
  task.abort(handle_2)
  future.resolve(Nil)
}
