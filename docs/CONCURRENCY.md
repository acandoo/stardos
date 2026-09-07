# Writing concurrent programs

`stardos`, whenever sensible, uses the `Future` type for returning various I/O functions. If you want to use I/O in your program, calling them directly doesn't work! This is because these functions can be combined to have multiple operations running _concurrently_.

## Futures

Instead of regular function calling, you can use the `use` syntax with `future.await`. While this is more verbose, it's this syntax that gives the flexibility for concurrent execution, through other functions like `future.all` and `future.race`.

```gleam
fn async_main() -> Future(Nil) {
  let future_one = future.new(fn() { io.println("This won't run!") })
  future.new(fn() { io.println("This won't run either!") })
  let future_two = future.new(fn() { io.println("This will run!") })
  let future_three = future.new(fn() { io.println("This will run concurrently with future 4!") })
  let future_four = future.new(fn() { io.println("This will run concurrently with future 3!") })
  use _ <- future.await(future_two)
  // The pipe syntax also works great!
  future_three
  |> future.join(future_four)
  |> future.await(then: fn(_) {
       io.println("This will run last!")
       future.resolve(Nil)
     })
}
```

When we `await` a Future, we must also return a Future. Thus, if you end with a synchronous function, you have to add `future.resolve` with the expected return type.

Note that on the JavaScript runtime, running computations within futures doesn't parallelize your program. So, doing something like this won't have any performance benefit:

```gleam
fn not_parallel() -> Future(#(Nil, Nil)) {
  let operation_one = future.new(fn() { expensive_computation() })
  let operation_two = future.new(fn() { another_expensive_computation() })

  future.join(
    operation_one,
    operation_two
  )
}
```

That example also ended with an asynchronous operation—`future.join`—allowing us to forgo `future.await` and `future.resolve`.

You may have noticed that the return type for `async_main` is also a `Future`. To execute `async_main`, you have to run it within a Task.

```gleam
fn main() -> Nil {
  task.spawn(async_main())
  Nil
}
```

If you try calling `main` from another function with the hope of having synchronous code again, it will return to the caller before all of the futures are executed. Any code that uses Futures must itself be a Future.

Sometimes, I/O operations need to give data in chunks. This next primitive covers that use case.

## Streams

A Stream gives values one at a time, with the next value behind a Future.

## Tasks

The biggest rule of thumb when writing programs is to minimize the number of tasks running. Most programs will only need one task, but when your concurrency needs become more complex, you'll need to create live Tasks. Combined with future primitives, tasks can also break up complex logic with many panics for undefined behavior. Every task is equivalent to a process on Erlang, or a live Promise on JavaScript. While you can `await` Tasks, you should think of Tasks as "panic boundaries" that can be restarted. Every `assert` in your program is traceable to a Task, and every task that depends on another task through `task.await` will also crash.
