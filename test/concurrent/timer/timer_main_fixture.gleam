import antimonia/mutable
import gleam/float
import gleam/int
import gleam/time/duration.{type Duration}
import gleam/time/timestamp
import internal/helpers
import shellout
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream
import stardos/concurrent/task
import stardos/concurrent/timer

// Accounts for overhead of spawning a process
const shell_tolerance_ms = 100

const upper_tolerance_ms = 10

const lower_tolerance_ms = 5

const interval_timeout_s = 5

pub fn main() -> Nil {
  task.spawn(async_main())
  Nil
}

fn async_main() {
  timer_sleep()
  use _ <- future.await(async_timer_timeout())
  use _ <- future.await(async_timer_interval())
  future.resolve(Nil)
}

// timer.sleep tests

fn timer_sleep() -> Nil {
  timer_sleep_tolerance()
}

fn timer_sleep_tolerance() -> Nil {
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

fn async_timer_timeout() -> Future(Nil) {
  timer_timeout_lifetime()
  use _ <- future.await(async_timer_timeout_tolerance())
  use _ <- future.await(async_timer_timeout_abort())
  future.resolve(Nil)
}

/// Lifetimes are tested in a separate fixture to ensure that
/// the process stays alive for the duration of the timer, and
/// that the timer is properly cleaned up after firing.
fn timer_timeout_lifetime() -> Nil {
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

fn async_timer_timeout_tolerance() -> Future(Nil) {
  use _ <- future.await(
    async_timer_timeout_instance(duration.milliseconds(100))
    |> future.join(async_timer_timeout_instance(duration.milliseconds(500)))
    |> future.join(async_timer_timeout_instance(duration.milliseconds(1000))),
  )
  future.resolve(Nil)
}

fn async_timer_timeout_instance(duration: Duration) -> Future(Nil) {
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

// timer.interval tests

fn async_timer_interval() -> Future(Nil) {
  // executed synchronously since shellout runs
  // commands blocking the event loop. again TODO
  // figure out how to design API to prevent this
  // footgun. this should only be a problem for
  // JavaScript, though.
  timer_interval_lifetime()
  use _ <- future.await(
    async_timer_interval_tolerance()
    |> future.join(async_timer_interval_abort())
    |> future.join(async_timer_interval_blocking()),
  )
  future.resolve(Nil)
}

/// Test that spawned intervals continue indefinitely.
fn timer_interval_lifetime() -> Nil {
  let runtime_base_flag = helpers.runtime_flags()
  let first = timestamp.system_time()
  let assert Ok(_) = shellout.which("timeout")
    as "timer.interval(lifetime): Timeout command should be available for this test"
  let assert Error(_) =
    shellout.command(
      run: "timeout",
      with: [
        int.to_string(interval_timeout_s),
        "gleam",
        "run",
        "-m",
        "concurrent/timer/timer_interval_lifetime_fixture",
        "-t",
        ..runtime_base_flag
      ],
      in: ".",
      opt: [],
    )
    as "timer.interval(lifetime): The interval should have been killed by the timeout command"
  let elapsed_s =
    timestamp.system_time()
    |> timestamp.difference(first, _)
    |> duration.to_seconds
    |> float.truncate

  assert elapsed_s >= interval_timeout_s
    as "timer.interval(lifetime): Elapsed time should be at least the timeout duration"
}

/// Test that intervals fire at approximately the correct time, allowing for some scheduling delay.
fn async_timer_interval_tolerance() -> Future(Nil) {
  // oh great immutable lucy please forgive me for my sins 🥺
  let #(count, set_count) = mutable.tuple_from(0)

  let interval_future = {
    timer.interval(duration.milliseconds(100))
    |> stream.subscribe(fn(_) {
      set_count(count() + 1)
      future.resolve(Nil)
    })
  }

  let assert Ok(handle) = task.spawn_abortable(interval_future)

  use _ <- future.await(timer.timeout(duration.milliseconds(550)))
  task.abort(handle)
  assert { count() >= 5 } && { count() <= 6 }
    as "timer.interval(tolerance): Interval should have fired approximately 5 times within the tolerance window"
  future.resolve(Nil)
}

/// Test that intervals can be aborted, and that they stop firing after being aborted.
/// this is kinda a duplicate of the tolerance test but less complex
fn async_timer_interval_abort() -> Future(Nil) {
  let interval_future = {
    use _ <- stream.subscribe(timer.interval(duration.milliseconds(50)))
    panic as "timer.timeout(abort): Timer should have been aborted (sync abortion)"
  }

  let interval_future_2 = {
    use _ <- stream.subscribe(timer.interval(duration.milliseconds(500)))
    panic as "timer.timeout(abort): Timer should have been aborted (async abortion)"
  }

  let assert Ok(handle) = task.spawn_abortable(interval_future)
  let assert Ok(handle_2) = task.spawn_abortable(interval_future_2)
  task.abort(handle)
  use _ <- future.await(timer.timeout(duration.milliseconds(100)))
  task.abort(handle_2)
  future.resolve(Nil)
}

/// Test that blocking for longer than the interval duration repositions the next interval correctly,
/// rather than executing a backlog.
fn async_timer_interval_blocking() -> Future(Nil) {
  let #(count, set_count) = mutable.tuple_from(0)
  let #(previous_timestamp, set_previous_timestamp) =
    mutable.tuple_from(timestamp.system_time())
  let #(wait, set_wait) = mutable.tuple_from(150)

  // Create an interval that fires every 50ms
  let interval_future = {
    timer.interval(duration.milliseconds(50))
    |> stream.subscribe(fn(_) {
      // Blocks for 150, then 100, then 50, then 1 ms on subsequent ticks.
      set_previous_timestamp(timestamp.system_time())
      use _ <- future.await(timer.timeout(duration.milliseconds(wait())))

      let current = timestamp.system_time()
      let duration_ms =
        timestamp.difference(previous_timestamp(), current)
        |> duration.to_milliseconds
        |> echo

      assert { duration_ms + lower_tolerance_ms >= wait() }
        && { duration_ms <= wait() + upper_tolerance_ms }
        as "timer.interval(blocking): Interval should fire within the expected time window"

      set_wait(case wait() - 50 {
        x if x > 0 -> x
        _ -> 1
      })
      set_previous_timestamp(current)
      set_count(count() + 1)
      future.resolve(Nil)
    })
  }

  let assert Ok(handle) = task.spawn_abortable(interval_future)

  // It takes 50ms before the intervals start,
  // then the intervals are 150, 100, 50, ... etc. long.
  // This should mean that we see 5 ticks:
  // 200ms, 300ms, 350ms, 400ms, 450ms
  use _ <- future.await(timer.timeout(duration.milliseconds(490)))
  task.abort(handle)

  echo count()

  assert count() == 5 as "timer.interval(blocking): Should fire 5 times"
  future.resolve(Nil)
}
