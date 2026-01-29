import gleam/time/duration.{type Duration}
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream.{type FutureStream}

@external(javascript, "./timer_ffi.mjs", "sleep")
pub fn sleep(duration: Duration) -> Future(Nil)

@external(javascript, "./timer_ffi.mjs", "interval")
pub fn interval(duration: Duration) -> FutureStream(Nil) {
  stream.FutureStream(next: fn() {
    use _ <- future.await(sleep(duration))
    future.resolve(stream.Next(Nil, interval(duration)))
  })
}
// TODO should there be better way of aborting besides AbortableTasks?
// maybe cleanup function on Future type?
