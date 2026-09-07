//// The `stream` module provides a way to create and work with
//// asynchronous streams of data. Streams can produce values
//// over time, allowing for processing of sequences of values
//// in an asynchronous manner.

import gleam/option.{type Option, None, Some}
import stardos/concurrent/future.{type Future}
import stardos/internal/future_ext
import stardos/internal/stream_base.{
  Continue, EagerContinue, EagerMaybeContinue, End, First, Last,
}

/// A Stream represents a stream of values of type `a`
/// that are produced asynchronously. Each value is produced
/// as a Future, allowing for non-blocking consumption of the stream.
/// 
/// Like Futures, Streams are inert and do not start producing
/// values until they are subscribed to in a Task spawned by a runtime.
pub type Stream(a) =
  stream_base.Stream(a)

pub fn from(list: List(a)) -> Stream(a) {
  case list {
    [] -> End
    [item] -> Last(item)
    [item, ..rest] -> Continue(item, future.resolve(from(rest)))
  }
}

@external(javascript, "./stream_ffi.mjs", "capture")
pub fn capture(fun: fn(fn(a) -> Nil) -> b) -> #(Stream(a), b)

pub fn memo(stream: Stream(a)) -> Stream(a) {
  // This is not ideal; the most optimal implementation in Erlang would spawn
  // one process that has each replacement Future send a message requesting
  // an index or something similar from the process. But processes are cheap anyways.
  // Plus it's not like you can be eager within the process iterating through,
  // in case the consumer doesn't want to generate all of the values
  let memo_stream_future = fn(stream_future) {
    use next_stream <- future_ext.map(future.memo(stream_future))
    memo(next_stream)
  }
  case stream {
    First(stream_future) -> First(memo_stream_future(stream_future))
    Continue(value, stream_future) ->
      Continue(value, memo_stream_future(stream_future))
    EagerContinue(value_future, stream_future) ->
      EagerContinue(
        future.memo(value_future),
        memo_stream_future(stream_future),
      )
    EagerMaybeContinue(value_option_future, stream_future) ->
      EagerMaybeContinue(
        future.memo(value_option_future),
        memo_stream_future(stream_future),
      )
    Last(a) -> Last(a)
    End -> End
  }
}

pub fn map(stream: Stream(a), with fun: fn(a) -> Future(b)) -> Stream(b) {
  case stream {
    First(next_stream_future) ->
      First({
        use stream <- future_ext.map(next_stream_future)
        map(stream, with: fun)
      })
    Continue(value, next_stream_future) ->
      EagerContinue(fun(value), next: {
        use stream <- future_ext.map(next_stream_future)
        map(stream, with: fun)
      })
    EagerContinue(value_future, next_stream_future) ->
      EagerContinue(
        {
          use value <- future.await(value_future)
          fun(value)
        },
        next: {
          use stream <- future_ext.map(next_stream_future)
          map(stream, with: fun)
        },
      )
    EagerMaybeContinue(value_option_future, next_stream_future) ->
      EagerMaybeContinue(
        {
          use value_option <- future.await(value_option_future)
          case value_option {
            Some(value) -> {
              use final <- future_ext.map(fun(value))
              Some(final)
            }
            None -> future.resolve(None)
          }
        },
        next: {
          use stream <- future_ext.map(next_stream_future)
          map(stream, with: fun)
        },
      )
    Last(value) -> EagerContinue(fun(value), future.resolve(End))
    End -> End
  }
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
        cb(value)
      }
      use #(_, next_stream) <- future.await(future.join(
        value_run,
        next_stream_future,
      ))
      each(to: next_stream, then: cb)
    }
    EagerMaybeContinue(value_option_future, next_stream_future) -> {
      let value_run = {
        use value_option <- future.await(value_option_future)
        case value_option {
          Some(value) -> cb(value)
          None -> future.resolve(Nil)
        }
      }
      use #(_, next_stream) <- future.await(future.join(
        value_run,
        next_stream_future,
      ))
      each(to: next_stream, then: cb)
    }
    End -> future.resolve(Nil)
    Last(value) -> {
      use _ <- future_ext.map(cb(value))
      Nil
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
      EagerMaybeContinue(
        eval_value(value, predicate),
        filter_internal(next_stream_future, with: predicate),
      )
    EagerContinue(value_future, next_stream_future) ->
      EagerMaybeContinue(
        {
          use value <- future.await(value_future)
          eval_value(value, predicate)
        },
        filter_internal(next_stream_future, with: predicate),
      )
    EagerMaybeContinue(value_option_future, next_stream_future) ->
      EagerMaybeContinue(
        {
          use value_option <- future.await(value_option_future)
          case value_option {
            Some(value) -> {
              use bool <- future_ext.map(predicate(value))
              case bool {
                True -> Some(value)
                False -> None
              }
            }
            None -> future.resolve(None)
          }
        },
        filter_internal(next_stream_future, with: predicate),
      )
    End -> End
    Last(value) ->
      // First is used over EagerMaybeContinue since
      // we only have one future chain going on at this point in time anyways.
      // No need to separate them out into two microtasks/processes.
      First({
        use predicate <- future_ext.map(predicate(value))
        case predicate {
          True -> Last(value)
          False -> End
        }
      })
  }
}

fn filter_internal(
  stream_future: Future(Stream(a)),
  with fun: fn(a) -> Future(Bool),
) -> Future(Stream(a)) {
  use stream <- future_ext.map(stream_future)
  filter(stream, keeping: fun)
}

fn eval_value(value: a, fun: fn(a) -> Future(Bool)) -> Future(Option(a)) {
  use bool <- future_ext.map(fun(value))
  case bool {
    True -> Some(value)
    False -> None
  }
}

pub fn filter_map(
  stream: Stream(a),
  with fun: fn(a) -> Future(Result(b, e)),
) -> Stream(b) {
  filter_map_internal(stream |> map(with: fun))
}

fn filter_map_internal(stream: Stream(Result(a, e))) -> Stream(a) {
  case stream {
    First(next_stream_future) | Continue(Error(_), next_stream_future) ->
      First(filter_map_internal_next(next_stream_future))
    Continue(Ok(value), next_stream_future) ->
      Continue(value, filter_map_internal_next(next_stream_future))
    EagerContinue(result_future, next_stream_future) ->
      EagerMaybeContinue(
        {
          use result <- future_ext.map(result_future)
          option.from_result(result)
        },
        filter_map_internal_next(next_stream_future),
      )
    EagerMaybeContinue(result_option_future, next_stream_future) ->
      EagerMaybeContinue(
        {
          use result_option <- future_ext.map(result_option_future)
          case result_option {
            None | Some(Error(_)) -> None
            Some(Ok(value)) -> Some(value)
          }
        },
        filter_map_internal_next(next_stream_future),
      )
    End | Last(Error(_)) -> End
    Last(Ok(value)) -> Last(value)
  }
}

fn filter_map_internal_next(
  stream_future: Future(Stream(Result(a, e))),
) -> Future(Stream(a)) {
  use stream <- future_ext.map(stream_future)
  filter_map_internal(stream)
}

pub fn fold(
  over stream: Stream(a),
  from initial: acc,
  with fun: fn(acc, a) -> Future(acc),
) -> Future(acc) {
  case stream {
    First(next_stream_future) -> {
      use next_stream <- future.await(next_stream_future)
      fold(over: next_stream, from: initial, with: fun)
    }
    Continue(value, next_stream_future) -> {
      let next_acc_future = fun(initial, value)
      use #(next_acc, next_stream) <- future.await(future.join(
        next_acc_future,
        next_stream_future,
      ))
      fold(over: next_stream, from: next_acc, with: fun)
    }
    EagerContinue(value_future, next_stream_future) -> {
      let next_acc_future = {
        use value <- future.await(value_future)
        fun(initial, value)
      }
      use #(next_acc, next_stream) <- future.await(future.join(
        next_acc_future,
        next_stream_future,
      ))
      fold(over: next_stream, from: next_acc, with: fun)
    }
    EagerMaybeContinue(value_option_future, next_stream_future) -> {
      let next_acc_future = {
        use value_option <- future.await(value_option_future)
        case value_option {
          Some(value) -> fun(initial, value)
          None -> future.resolve(initial)
        }
      }
      use #(next_acc, next_stream) <- future.await(future.join(
        next_acc_future,
        next_stream_future,
      ))
      fold(over: next_stream, from: next_acc, with: fun)
    }
    End -> future.resolve(initial)
    Last(value) -> fun(initial, value)
  }
}
