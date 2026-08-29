import stardos/concurrent/future.{type Future}

/// To be used internally to optimize operations.
/// This is not exposed to users as it would lead to API confusion,
/// and comes with minimal performance benefit.
@external(javascript, "../concurrent/future_ffi.mjs", "mapFuture")
pub fn map(future: Future(a), map: fn(a) -> b) -> Future(b)
