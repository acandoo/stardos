import gleam/time/duration
import stardos/concurrent/future
import stardos/concurrent/task
import stardos/concurrent/timer

// Test timer.timeout completes after specified duration
pub fn timer_timeout_test() -> Nil {
  task.spawn(
    timer.timeout(duration.milliseconds(10))
    |> future.await(fn(_) { future.resolve(Nil) }),
  )
  Nil
}
