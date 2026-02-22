import gleam/time/duration.{type Duration}
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream.{type Stream}

@external(javascript, "./timer_ffi.mjs", "sleep")
pub fn sleep(duration: Duration) -> Future(Nil)

// @external(javascript, "./timer_ffi.mjs", "interval")
pub fn interval(duration: Duration) -> Stream(Nil) {
  // This isn't *perfectly* accurate, since the callback will be scheduled after the duration

  stream.First(next: {
    use _ <- future.await(sleep(duration))
    future.resolve(stream.Continue(Nil, future.resolve(interval_loop(duration))))
  })
}

fn interval_loop(duration: Duration) -> Stream(Nil) {
  stream.Continue(Nil, {
    use _ <- future.await(sleep(duration))
    future.resolve(interval_loop(duration))
  })
}
// TODO should there be better way of aborting besides AbortableTasks?
// maybe cleanup function on Future type?
