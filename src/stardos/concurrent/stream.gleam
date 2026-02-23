//// The `stream` module provides a way to create and work with
//// asynchronous streams of data. Streams can produce values
//// over time, allowing for processing of sequences of values
//// in an asynchronous manner.

import stardos/concurrent/future.{type Future}

/// A Stream represents a stream of values of type `a`
/// that are produced asynchronously. Each value is produced
/// as a Future, allowing for non-blocking consumption of the stream.
/// 
/// Like Futures, Streams are inert and do not start producing
/// values until they are subscribed to in a Task spawned by a runtime.
pub type Stream(a) {
  First(next: Future(Stream(a)))
  Continue(value: a, next: Future(Stream(a)))
  Last(value: a)
}

/// Subscribes to a Stream, invoking the provided callback
/// function for each item produced by the stream. The subscription
/// continues until the stream produces its last item.
/// 
/// ## Example
///
/// ```gleam
/// pub fn main() -> Nil {
///   // stream isn't started by this
///   let my_stream: Stream(String) = stream_creator()
/// 
///   // subscribing produces a Future, so still inert
///   let subscription = stream.subscribe(
///     to: my_stream,
///     then: fn(message) {
///       io.println(message)
///       future.resolve(Nil)
///     },
///   )
/// 
///   // spawning the task starts the stream
///   task.spawn(subscription)
///   Nil
/// }
/// ```
pub fn subscribe(
  to stream: Stream(a),
  then cb: fn(a) -> Future(Nil),
) -> Future(Nil) {
  case stream {
    First(next_stream) -> {
      use next <- future.await(next_stream)
      subscribe(to: next, then: cb)
    }
    Continue(value, next_stream) -> {
      use _ <- future.await(cb(value))
      use next <- future.await(next_stream)
      subscribe(to: next, then: cb)
    }
    Last(value) -> {
      use _ <- future.await(cb(value))
      future.resolve(Nil)
    }
  }
}
