import gleam/time/duration
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream
import stardos/concurrent/task
import stardos/concurrent/timer

pub fn main() -> Nil {
  task.spawn(async_main())
  Nil
}

fn async_main() -> Future(Nil) {
  use _ <- future.await(
    duration.milliseconds(100)
    |> timer.interval
    |> stream.subscribe(fn(_) { future.resolve(Nil) }),
  )
  future.resolve(Nil)
}
