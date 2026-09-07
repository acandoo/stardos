import gleam/option.{type Option}
import stardos/concurrent/future.{type Future}

pub type Stream(a) {
  /// This is also used in place of an EagerMaybeContinue in operations evaluating the final item of an iterator
  First(next: Future(Stream(a)))
  /// If the first value is able to be known without blocking,
  /// it is okay for APIs to start with a Continue value rather than wrapping
  /// it within a `First(future.resolve(...))`.
  Continue(value: a, next: Future(Stream(a)))
  /// This exists so that accumulators can simultaneously wait for
  /// the next item and the next stream.
  /// This has to be done on the accumulator side as
  /// returning a Continue would block fetching the base stream when awaiting the derived value.
  EagerContinue(value: Future(a), next: Future(Stream(a)))
  /// Similar to EagerContinue, except this also covers lazy filtering
  /// and similar operations where derived Streams contain fewer items.
  EagerMaybeContinue(value: Future(Option(a)), next: Future(Stream(a)))
  Last(value: a)
  End
}
