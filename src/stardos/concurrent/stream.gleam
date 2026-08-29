//// The `stream` module provides a way to create and work with
//// asynchronous streams of data. Streams can produce values
//// over time, allowing for processing of sequences of values
//// in an asynchronous manner.

import gleam/option.{type Option}
import gleam/result
import stardos/concurrent/future.{type Future}

/// A Stream represents a stream of values of type `a`
/// that are produced asynchronously. Each value is produced
/// as a Future, allowing for non-blocking consumption of the stream.
/// 
/// Like Futures, Streams are inert and do not start producing
/// values until they are subscribed to in a Task spawned by a runtime.
pub type Stream(a) {
  First(next: Future(Stream(a)))
  /// If the first value is able to be known without blocking,
  /// it is okay for APIs to start with a Continue value rather than wrapping
  /// it within a `First(future.resolve(...))`.
  Continue(value: a, next: Future(Stream(a)))
  EagerContinue(value: Future(a), next: Future(Stream(a)))
  Last(value: Option(a))
}

pub fn from(list: List(a)) -> Stream(a) {
  case list {
    [] -> Last(option.None)
    [item] -> Last(option.Some(item))
    [item, ..rest] -> Continue(item, future.resolve(from(rest)))
  }
}

/// note to self: this has to be done externally
pub fn capture(fun: fn(fn(a) -> Nil) -> b) -> #(Stream(a), b) {
  todo
}

pub fn memo(stream: Stream(a)) -> Stream(a) {
  todo
}

pub fn map(stream: Stream(a), with fun: fn(a) -> Future(b)) -> Stream(b) {
  case stream {
    First(next_stream_future) ->
      First({
        use stream <- future.await(next_stream_future)
        future.resolve(map(stream, with: fun))
      })
    Continue(value, next_stream_future) ->
      EagerContinue(fun(value), next: {
        use stream <- future.await(next_stream_future)
        future.resolve(map(stream, with: fun))
      })
    EagerContinue(value_future, next_stream_future) ->
      EagerContinue(
        {
          use value <- future.await(value_future)
          fun(value)
        },
        next: {
          use stream <- future.await(next_stream_future)
          future.resolve(map(stream, with: fun))
        },
      )
    Last(option.None) -> Last(option.None)
    Last(option.Some(value)) ->
      EagerContinue(fun(value), future.resolve(Last(option.None)))
  }
}

pub fn to_list(stream: Stream(a)) -> Future(List(a)) {
  todo
}

/// is this worth implementing?
pub fn append(first: Stream(a), second: Stream(a)) -> Stream(a) {
  todo
}

pub fn chunk(in stream: Stream(a), by f: fn(a) -> Future(k)) -> Stream(List(a)) {
  todo
}

pub fn combination_pairs(stream: Stream(a)) -> Stream(#(a, a)) {
  todo
}

pub fn combinations(stream: Stream(a), by n: Int) -> Stream(List(a)) {
  todo
}

pub fn contains(stream: Stream(a), any elem: a) -> Future(Bool) {
  todo
}

pub fn drop(from stream: Stream(a), up_to n: Int) -> Stream(a) {
  todo
}

pub fn drop_while(
  in stream: Stream(a),
  satisfying predicate: fn(a) -> Future(Bool),
) -> Stream(a) {
  todo
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
pub fn each(to stream: Stream(a), then cb: fn(a) -> Future(Nil)) -> Future(Nil) {
  case stream {
    First(next_stream_future) -> {
      use next_stream <- future.await(next_stream_future)
      each(to: next_stream, then: cb)
    }
    Continue(value, next_stream_future) -> {
      use _ <- future.await(cb(value))
      use next_stream <- future.await(next_stream_future)
      each(to: next_stream, then: cb)
    }
    EagerContinue(value_future, next_stream_future) -> {
      let value_run = {
        use value <- future.await(value_future)
        future.resolve(cb(value))
      }
      use #(_, next_stream) <- future.await(future.join(
        value_run,
        next_stream_future,
      ))
      each(to: next_stream, then: cb)
    }
    Last(option.None) -> future.resolve(Nil)
    Last(option.Some(value)) -> {
      use _ <- future.await(cb(value))
      future.resolve(Nil)
    }
  }
}

pub fn filter(
  stream: Stream(a),
  keeping predicate: fn(a) -> Future(Bool),
) -> Stream(a) {
  case stream {
    First(next_stream_future) ->
      First(filter_internal(next_stream_future, with: predicate))
    Continue(value, next_stream_future) ->
      First(eval_value(value, predicate, next_stream_future))
    EagerContinue(value_future, next_stream_future) ->
      First({
        use value <- future.await(value_future)
        eval_value(value, predicate, next_stream_future)
      })
    Last(option.None) -> Last(option.None)
    Last(option.Some(value)) ->
      First({
        use predicate <- future.await(predicate(value))
        future.resolve(case predicate {
          True -> Last(option.Some(value))
          False -> Last(option.None)
        })
      })
  }
}

fn filter_internal(
  stream_future: Future(Stream(a)),
  with fun: fn(a) -> Future(Bool),
) -> Future(Stream(a)) {
  use stream <- future.await(stream_future)
  case stream {
    First(next_stream_future) -> filter_internal(next_stream_future, with: fun)
    Continue(value, next_stream_future) -> {
      eval_value(value, fun, next_stream_future)
    }
    EagerContinue(value_future, next_stream_future) -> {
      use value <- future.await(value_future)
      eval_value(value, fun, next_stream_future)
    }
    Last(option.None) -> future.resolve(Last(option.None))
    Last(option.Some(value)) -> {
      use predicate <- future.await(fun(value))
      future.resolve(case predicate {
        True -> Last(option.Some(value))
        False -> Last(option.None)
      })
    }
  }
}

fn eval_value(
  value: a,
  fun: fn(a) -> Future(Bool),
  next_stream_future: Future(Stream(a)),
) -> Future(Stream(a)) {
  use predicate <- future.await(fun(value))
  case predicate {
    True -> future.resolve(Continue(value, next_stream_future))
    False -> filter_internal(next_stream_future, with: fun)
  }
}

pub fn filter_map(
  stream: Stream(a),
  with fun: fn(a) -> Future(Result(b, e)),
) -> Stream(b) {
  stream
  |> map(fun)
  |> filter(fn(a) { future.resolve(result.is_ok(a)) })
  |> map(fn(a) {
    let assert Ok(val) = a
    future.resolve(val)
  })
}

pub fn fold(
  over stream: Stream(a),
  from initial: acc,
  with fun: fn(acc, a) -> Future(acc),
) -> acc {
  todo
}
