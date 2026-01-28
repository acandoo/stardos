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
/// you shouldn't use this function directly, as the main utility of this
/// function is to appease the type system in certain scenarios.
///  
/// ## Examples
/// 
/// Create a Future that produces `Nil`:
/// 
/// ```gleam
/// future.new(fn() { Nil })
/// // -> Future(Nil)
/// ```
/// 
/// Run a blocking computation in a Future (This does NOT make it
/// non-blocking on JavaScript!):
/// 
/// ```gleam
/// future.new(fn() {
///   io.println("Hello, Lucy!")
/// })
/// // -> Future(Nil)
/// ```
/// 
@external(javascript, "./future_ffi.mjs", "newFuture")
pub fn new(compute: fn() -> result) -> Future(result)

/// Subscribes to the completion of a Future, allowing further operations to be
/// performed once the Future resolves.
///  
/// ## Examples
/// 
/// Use `await` to get the result of a Future:
/// 
/// ```gleam
/// let my_future = future.new(fn() { 42 })
/// let result_future = future.await(my_future, fn(value) {
///   value + 1
/// })
/// // -> Future(Int)
/// ```
/// 
/// Use `use` syntax to await without indentation:
/// 
/// ```gleam
/// let my_future = future.new(fn() { 42 })
/// let my_other_future = future.new(fn() { "Lucy" })
/// 
/// // Note that my_other_future will only be scheduled *after*
/// // my_future completes, since we are awaiting it first.
/// use value <- future.await(my_future)
/// use other_value <- future.await(my_other_future)
/// value + 1
/// // -> Future(Future(Int))
/// ```
///
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

/// Joins a list of Futures, producing a new Future that resolves
/// when all input Futures have resolved. When spawned, the inner
/// futures will be executed concurrently, and the resulting Future
/// will contain a list with the results of all Futures.
@external(javascript, "./future_ffi.mjs", "joinFutures")
pub fn all(futures: List(Future(result))) -> Future(List(result))

/// Flattens a double nested Future into a single Future.
/// This often occurs after multiple `await` calls.
@external(javascript, "./future_ffi.mjs", "flattenFuture")
pub fn flatten(future: Future(Future(result))) -> Future(result)

pub fn flat_await(
  future: Future(result),
  then cb: fn(result) -> Future(new),
) -> Future(new) {
  flatten(await(future, fn(value) { cb(value) }))
}
// fn testing_fn() {
//   let f1 = new(fn() { 1 })
//   let f2 = new(fn() { 2 })
//   let f3 = new(fn() { 3 })
//   let f4 = new(fn() { 4 })
//   let f5 = new(fn() { 5 })
//   let f6 = new(fn() { 6 })
//   let f7 = new(fn() { 7 })
//   let f8 = new(fn() { 8 })

//   let joined =
//     f1
//     |> join(f2)
//     |> join(f3)
//     |> join(f4)
//   let joined2 =
//     f5
//     |> join(f6)
//     |> join(f7)
//     |> join(f8)
//   use #(#(#(a, b), c), d) <- flat_await(joined)
//   let result1 = a + b + c + d
//   use #(#(#(e, f), g), h) <- await(joined2)
//   let result2 = e + f + g + h
//   result1 + result2
//   // is it better to do flat_await or future.return + await as flat_await?
//   // use #(#(#(a, b), c), d) <- future.await(joined)
//   // let result1 = a + b + c + d
//   // use #(#(#(e, f), g), h) <- future.await(joined2)
//   // let result2 = e + f + g + h
//   // future.return(result1 + result2)
// }
