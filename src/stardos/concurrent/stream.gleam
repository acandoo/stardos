//// The `stream` module provides a way to create and work with
//// asynchronous streams of data. Streams can produce values
//// over time, allowing for processing of sequences of values
//// in an asynchronous manner.

import stardos/concurrent/future.{type Future}

/// A FutureStream represents a stream of values of type `a`
/// that are produced asynchronously. Each value is produced
/// as a Future, allowing for non-blocking consumption of the stream.
pub type FutureStream(a) {
  FutureStream(next: fn() -> Future(Step(a)))
}

pub type Step(a) {
  Next(a, FutureStream(a))
  Last(a)
}

pub fn subscribe(
  to stream: FutureStream(a),
  then cb: fn(a) -> Nil,
) -> Future(Nil) {
  use val <- future.flat_await(stream.next())
  case val {
    Next(item, rest) -> {
      cb(item)
      subscribe(to: rest, then: cb)
    }
    Last(item) -> {
      cb(item)
      future.new(fn() { Nil })
    }
  }
}
