import gleam/io
import gleam/time/duration
import stardos/concurrent/future.{type Future}
import stardos/concurrent/task
import stardos/concurrent/timer

pub fn main() -> Nil {
  task.spawn(async_main())
  Nil
}

fn async_main() -> Future(Nil) {
  io.println("Starting wait...")
  use _ <- future.await(timer.timeout(duration.milliseconds(1000)))
  io.println("Done waiting!")
  future.resolve(Nil)
}
