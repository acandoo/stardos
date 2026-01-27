//// The `future` module provides a way to create and compose
//// asynchronous operations, known as futures. Futures can
//// depend on the results of other futures, allowing for
//// complex asynchronous workflows to be built in a structured
//// manner.
//// 
//// Note that, unlike JavaScript Promises, Gleam futures are *inert*,
//// meaning they do not start executing until explicitly spawned in a Task
//// by a runtime. This is somewhat unlike Rust Futures, which can be `await`ed
//// directly in an async main function. This distinction is due to Gleam's
//// fundamentally synchronous execution model and the requirements of the Erlang
//// and JavaScript runtimes.

/// A Future represents an asynchronous operation that will
/// eventually produce a result of type `result`. It may depend
/// on the completion of a previous Future of type `prev`.
///
/// `prev` may be `Nil` if there is no dependency, another Future type, or a nested tuple
/// structure of previous dependencies.
pub type Future(result)

/// Creates a new Future that will execute the provided computation
/// when the Future is spawned in a Task by a runtime. In all likelihood
/// you shouldn't use this function directly, as 
@external(javascript, "./future_ffi.mjs", "newFuture")
pub fn new(compute: fn() -> result) -> Future(result)

/// Subscribes to the completion of a Future, allowing further operations to be
/// performed once the Future resolves.
///  
/// ## Examples
/// 
/// ```gleam
/// use 
@external(javascript, "./future_ffi.mjs", "awaitFuture")
pub fn await(
  future prev: Future(result),
  then cb: fn(result) -> new,
) -> Future(new)

/// Joins two Futures, producing a new Future that resolves
/// when both input Futures have resolved. When spawned, the inner
/// futures will be executed concurrently, and the resulting Future
/// will contain a tuple with the results of both Futures.
@external(javascript, "./future_ffi.mjs", "joinFutures")
pub fn join(
  future1: Future(result1),
  future2: Future(result2),
) -> Future(#(result1, result2))

/// Unwraps a double nested Future, flattening it into a single Future.
/// This often occurs after multiple `await` calls.
@external(javascript, "./future_ffi.mjs", "unwrapFuture")
pub fn unwrap(future: Future(Future(result))) -> Future(result)
