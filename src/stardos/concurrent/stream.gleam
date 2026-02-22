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
///     then: io.println,
///   )
/// 
///   // spawning the task starts the stream
///   task.spawn(subscription)
///   Nil
/// }
/// ```
/// 
pub type Stream(a) {
  First(next: Future(Stream(a)))
  Continue(value: a, next: Future(Stream(a)))
  Last(value: a)
}

// note: there is a problem with timing sensitive applications
// since control over the scheduling is blocked by the callback.
// futures are not eager, so timing issues may arise
// though i'm not 100% sure, i'll have to look into it more later

/// Subscribes to a Stream, invoking the provided callback
/// function for each item produced by the stream. The subscription
/// continues until the stream produces its last item.
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
