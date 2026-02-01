import gleam/list
import stardos/concurrent/future
import stardos/concurrent/task

// Test basic future creation and resolution
pub fn future_resolve_test() -> Nil {
  task.spawn(
    future.new(fn() { 42 })
    |> future.await(fn(result) {
      assert result == 42
      future.resolve(Nil)
    }),
  )
  Nil
}

// Test future.join combines two futures
pub fn future_join_test() -> Nil {
  task.spawn(
    future.new(fn() { 1 })
    |> future.join(future.new(fn() { 2 }))
    |> future.await(fn(pair) {
      let #(a, b) = pair
      assert a == 1
      assert b == 2
      future.resolve(Nil)
    }),
  )
  Nil
}

// Test future.all collects multiple futures
pub fn future_all_test() -> Nil {
  task.spawn(
    future.all([
      future.new(fn() { 1 }),
      future.new(fn() { 2 }),
      future.new(fn() { 3 }),
    ])
    |> future.await(fn(results) {
      assert results == [1, 2, 3]
      future.resolve(Nil)
    }),
  )
  Nil
}

// Test future.first returns the first completed future
pub fn future_first_test() -> Nil {
  task.spawn(
    future.first([
      future.new(fn() { 1 }),
      future.new(fn() { 2 }),
      future.new(fn() { 3 }),
    ])
    |> future.await(fn(result) {
      assert result == 1
      future.resolve(Nil)
    }),
  )
  Nil
}

// Test multiple joined futures with complex nesting
pub fn future_join_chain_test() -> Nil {
  let f1 = future.new(fn() { 1 })
  let f2 = future.new(fn() { 2 })
  let f3 = future.new(fn() { 3 })
  let f4 = future.new(fn() { 4 })

  let joined =
    f1
    |> future.join(f2)
    |> future.join(f3)
    |> future.join(f4)

  task.spawn(
    joined
    |> future.await(fn(nested_pair) {
      let #(#(#(a, b), c), d) = nested_pair
      let result = a + b + c + d
      assert result == 10
      future.resolve(Nil)
    }),
  )
  Nil
}

// Test all futures with arithmetic operations
pub fn future_all_arithmetic_test() -> Nil {
  task.spawn(
    future.all([
      future.new(fn() { 10 }),
      future.new(fn() { 20 }),
      future.new(fn() { 30 }),
      future.new(fn() { 40 }),
    ])
    |> future.await(fn(results) {
      let sum = list.fold(results, 0, fn(acc, x) { acc + x })
      assert sum == 100
      future.resolve(Nil)
    }),
  )
  Nil
}
