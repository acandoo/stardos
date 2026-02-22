import gleam/time/duration.{type Duration}
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream.{type Stream}

@external(javascript, "./timer_ffi.mjs", "sleep")
pub fn sleep(duration: Duration) -> Nil

@external(javascript, "./timer_ffi.mjs", "timeout")
pub fn timeout(duration: Duration) -> Future(Nil)

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
