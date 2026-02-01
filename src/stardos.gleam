import gleam/int
import gleam/io
import gleam/list
import gleam/time/duration
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream
import stardos/concurrent/task
import stardos/concurrent/timer
import stardos/env

pub fn main() -> Nil {
  list.each(env.args(), io.println)
  task.spawn(async_main())
  io.println("Async function spawned.")
  let program_path = env.program()
  io.println("Program path: " <> program_path)
  let runtime = env.runtime()
  case runtime {
    env.Erlang(path) -> io.println("Running on Erlang at: " <> path)
    env.JavaScript(js_runtime) ->
      case js_runtime {
        env.Node(path) -> io.println("Running on Node.js at: " <> path)
        env.Deno(path) -> io.println("Running on Deno at: " <> path)
        env.Bun(path) -> io.println("Running on Bun at: " <> path)
        env.Unknown -> io.println("Running on an unknown JavaScript runtime.")
      }
  }
  task.spawn(sleep_example())
  task.spawn(interval_example())
  Nil
}

fn interval_example() -> Future(Nil) {
  let timer_stream = timer.interval(duration.seconds(2))
  let subscription =
    stream.subscribe(to: timer_stream, then: fn(_) {
      io.println("Interval tick")
    })
  io.println("interval should not be spawned")
  use _ <- future.await(timer.sleep(duration.seconds(3)))
  io.println("Starting interval.")
  let assert Ok(interval_task) = task.spawn_abortable(subscription)
  use _ <- future.await(timer.sleep(duration.seconds(10)))
  io.println("Stopping interval.")
  task.abort(interval_task)
  future.resolve(Nil)
}

fn sleep_example() -> Future(Nil) {
  use _ <- future.await(timer.sleep(duration.seconds(3)))
  io.println("Slept for 3 seconds.")
  future.resolve(Nil)
}

fn async_main() -> Future(Nil) {
  let f1 =
    future.new(fn() {
      io.println("Running future 1")
      1
    })
  let f2 =
    future.new(fn() {
      io.println("Running future 2")
      2
    })
  let f3 =
    future.new(fn() {
      io.println("Running future 3")
      3
    })
  let f4 =
    future.new(fn() {
      io.println("Running future 4")
      4
    })
  let f5 =
    future.new(fn() {
      io.println("Running future 5")
      5
    })
  let f6 =
    future.new(fn() {
      io.println("Running future 6")
      6
    })
  let f7 =
    future.new(fn() {
      io.println("Running future 7")
      7
    })
  let f8 =
    future.new(fn() {
      io.println("Running future 8")
      8
    })

  let joined =
    f1
    |> future.join(f2)
    |> future.join(f3)
    |> future.join(f4)
  let joined2 =
    f5
    |> future.join(f6)
    |> future.join(f7)
    |> future.join(f8)
  let all1 = future.all([f1, f2, f3, f4])
  let all2 = future.all([f5, f6, f7, f8])
  let race = future.first([f1, f2, f3, f4, f5, f6, f7, f8])
  use #(#(#(a, b), c), d) <- future.await(joined)
  let result1 = a + b + c + d
  io.println("Result 1: " <> int.to_string(result1))
  use #(#(#(e, f), g), h) <- future.await(joined2)
  let result2 = e + f + g + h
  io.println("Result 2: " <> int.to_string(result2))
  use list1 <- future.await(all1)
  list.map(list1, fn(a) { io.println(int.to_string(a)) })
  use list2 <- future.await(all2)
  list.map(list2, fn(a) { io.println(int.to_string(a)) })
  use race_result <- future.await(race)
  io.println("Race result: " <> int.to_string(race_result))
  future.resolve(Nil)
}
