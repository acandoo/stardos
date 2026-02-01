//// The `stream` module provides a way to create and work with
//// asynchronous streams of data. Streams can produce values
//// over time, allowing for processing of sequences of values
//// in an asynchronous manner.

import stardos/concurrent/future.{type Future}

/// A FutureStream represents a stream of values of type `a`
/// that are produced asynchronously. Each value is produced
/// as a Future, allowing for non-blocking consumption of the stream.
/// 
/// Like Futures, FutureStreams are inert and do not start producing
/// values until they are subscribed to in a Task spawned by a runtime.
/// 
/// ## Example
///
/// ```gleam
/// pub fn main() -> Nil {
///   // stream isn't started by this
///   let my_stream: FutureStream(String) = stream_creator()
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
pub type FutureStream(a) {
  FutureStream(next: fn() -> Future(Step(a)))
}

pub type Step(a) {
  Next(a)
  Last
}

// note: there is a problem with timing sensitive applications
// since control over the scheduling is blocked by the callback.
// futures are not eager, so timing issues may arise
// though i'm not 100% sure, i'll have to look into it more later

/// Subscribes to a FutureStream, invoking the provided callback
/// function for each item produced by the stream. The subscription
/// continues until the stream produces its last item.
pub fn subscribe(
  to stream: FutureStream(a),
  then cb: fn(a) -> Nil,
) -> Future(Nil) {
  use val <- future.await(stream.next())
  case val {
    Next(item) -> {
      cb(item)
      subscribe(to: stream, then: cb)
    }
    Last -> future.resolve(Nil)
  }
}
