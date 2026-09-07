import gleam/time/duration.{type Duration}
import stardos/concurrent/future.{type Future}

pub fn timeout(duration: Duration) -> Future(Nil) {
  timeout_ms(duration.to_milliseconds(duration))
}

@external(javascript, "./timer_ffi.mjs", "timeoutMs")
fn timeout_ms(duration: Int) -> Future(Nil)

/// Call a callback function, waiting a duration between calls.
/// This function returns a Future, but do not await it,
/// as it will never resolve to a value!
/// To use the interval, spawn it using a Task.
pub fn interval(every duration: Duration, call cb: fn() -> Nil) -> Future(Nil) {
  interval_ms(duration.to_milliseconds(duration), cb)
}

@external(javascript, "./timer_ffi.mjs", "intervalMs")
fn interval_ms(duration: Int, cb: fn() -> Nil) -> Future(Nil)
