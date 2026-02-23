import gleam/time/duration.{type Duration}
import gleam/time/timestamp
import internal/helpers
import shellout
import stardos/concurrent/future.{type Future}
import stardos/concurrent/task
import stardos/concurrent/timer

// Accounts for overhead of spawning a process
const shell_tolerance_ms = 100

const upper_tolerance_ms = 10

const lower_tolerance_ms = 5

pub fn main() -> Nil {
  timer_sleep()
  timer_timeout()
}

// timer.sleep tests

pub fn timer_sleep() -> Nil {
  timer_sleep_tolerance()
}

pub fn timer_sleep_tolerance() -> Nil {
  let first = timestamp.system_time()
  timer.sleep(duration.milliseconds(100))
  let elapsed_ms =
    timestamp.system_time()
    |> timestamp.difference(first, _)
    |> duration.to_milliseconds

  // The fixture has some delay in running,
  // so we check that at least that much time has elapsed,
  // allowing some tolerance for scheduling delays
  assert { elapsed_ms + lower_tolerance_ms >= 100 }
    && { elapsed_ms <= 100 + upper_tolerance_ms }
    as "timer.sleep(tolerance): Elapsed time should be within tolerance"
}

// timer.timeout tests

pub fn timer_timeout() -> Nil {
  timer_timeout_lifetime()
  timer_timeout_tolerance()
  timer_timeout_abort()
}

/// Lifetimes are tested in a separate fixture to ensure that
/// the process stays alive for the duration of the timer, and
/// that the timer is properly cleaned up after firing.
pub fn timer_timeout_lifetime() -> Nil {
  let runtime_base_flag = helpers.runtime_flags()

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
    |> echo

  // The fixture waits for 1000ms, so we check that at least that much time has elapsed, allowing some tolerance for scheduling delays
  assert { elapsed_ms + lower_tolerance_ms >= 1000 }
    && { elapsed_ms <= 1000 + upper_tolerance_ms + shell_tolerance_ms }
    as "timer.timeout(lifetime): Elapsed time should be within tolerance"
}

pub fn timer_timeout_tolerance() -> Nil {
  task.spawn(async_timer_timeout_tolerance(duration.milliseconds(100)))
  task.spawn(async_timer_timeout_tolerance(duration.milliseconds(500)))
  task.spawn(async_timer_timeout_tolerance(duration.milliseconds(1000)))
  Nil
}

fn async_timer_timeout_tolerance(duration: Duration) -> Future(Nil) {
  let first = timestamp.system_time()
  let duration_ms = duration.to_milliseconds(duration)

  use _ <- future.await(timer.timeout(duration))
  let elapsed_ms =
    timestamp.system_time()
    |> timestamp.difference(first, _)
    |> duration.to_milliseconds
    |> echo
  echo duration_ms

  // Allow some tolerance for scheduling delays
  // Also, for some reason this needs brackets?
  assert { elapsed_ms + lower_tolerance_ms >= duration_ms }
    && { elapsed_ms <= duration_ms + upper_tolerance_ms }
    as "timer.timeout(tolerance): Elapsed time should be within tolerance"
  future.resolve(Nil)
}

pub fn timer_timeout_abort() -> Nil {
  task.spawn(async_timer_timeout_abort())
  Nil
}

fn async_timer_timeout_abort() -> Future(Nil) {
  let timeout_future = {
    use _ <- future.await(timer.timeout(duration.milliseconds(50)))
    panic as "timer.timeout(abort): Timer should have been aborted (sync abortion)"
  }

  let timeout_future_2 = {
    use _ <- future.await(timer.timeout(duration.milliseconds(500)))
    panic as "timer.timeout(abort): Timer should have been aborted (async abortion)"
  }

  let assert Ok(handle) = task.spawn_abortable(timeout_future)
  let assert Ok(handle_2) = task.spawn_abortable(timeout_future_2)
  task.abort(handle)
  use _ <- future.await(timer.timeout(duration.milliseconds(100)))
  task.abort(handle_2)
  future.resolve(Nil)
}
