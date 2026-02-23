import gleam/time/duration.{type Duration}
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream.{type Stream}

pub fn sleep(dur: Duration) -> Nil {
  sleep_ms(duration.to_milliseconds(dur))
}

@external(javascript, "./timer_ffi.mjs", "sleepMs")
fn sleep_ms(duration: Int) -> Nil

pub fn timeout(duration: Duration) -> Future(Nil) {
  timeout_ms(duration.to_milliseconds(duration))
}

@external(javascript, "./timer_ffi.mjs", "timeoutMs")
fn timeout_ms(duration: Int) -> Future(Nil)

/// Creates a Stream that produces `Nil` at regular intervals specified by the `duration`.
@external(javascript, "./timer_ffi.mjs", "interval")
pub fn interval(duration: Duration) -> Stream(Nil) {
  // This isn't *perfectly* accurate, since the duration will wait for the callback
  // when subscribed to, causing it to drift over time.

  stream.First(next: {
    use _ <- future.await(timeout(duration))
    future.resolve(interval_loop(duration))
  })
}

fn interval_loop(duration: Duration) -> Stream(Nil) {
  stream.Continue(Nil, {
    use _ <- future.await(timeout(duration))
    future.resolve(interval_loop(duration))
  })
}
// TODO should there be better way of aborting besides AbortableTasks?
// maybe cleanup function on Future type?
