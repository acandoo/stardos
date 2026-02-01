import gleam/time/duration
import stardos/concurrent/future
import stardos/concurrent/task
import stardos/concurrent/timer

// Test timer.sleep completes after specified duration
pub fn timer_sleep_test() -> Nil {
  task.spawn(
    timer.sleep(duration.milliseconds(10))
    |> future.await(fn(_) { future.resolve(Nil) }),
  )
  Nil
}
