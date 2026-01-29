import gleam/int
import gleam/io
import gleam/list
import stardos/env
import stardos/concurrent/future.{type Future}
import stardos/concurrent/task

pub fn main() -> Nil {
  list.each(env.args(), io.println)
  task.spawn(async_main())
  io.println("Main function complete.")
}

fn async_main() -> Future(Nil) {
  let f1 = future.new(fn() { 1 })
  let f2 = future.new(fn() { 2 })
  let f3 = future.new(fn() { 3 })
  let f4 = future.new(fn() { 4 })
  let f5 = future.new(fn() { 5 })
  let f6 = future.new(fn() { 6 })
  let f7 = future.new(fn() { 7 })
  let f8 = future.new(fn() { 8 })

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
  list.map(list1, fn(a) {io.println(int.to_string(a))})
  use list2 <- future.await(all2)
  list.map(list2, fn(a) {io.println(int.to_string(a))})
  use race_result <- future.await(race)
  io.println("Race result: " <> int.to_string(race_result))
  future.resolve(Nil)
}
