import gleam/time/duration
import stardos/concurrent/future
import stardos/concurrent/task
import stardos/timer

// Test task spawning
pub fn task_spawn_test() -> Nil {
  let f = future.new(fn() { 100 })
  task.spawn(f)
  Nil
}

// Test abortable task creation and abort
pub fn task_abort_test() -> Nil {
  let f = timer.timeout(duration.seconds(5))
  let abortable_task = task.spawn_abortable(f)
  abortable_task.abort()
  task.spawn({
    use result <- task.await(abortable_task.task)
    let assert Error(_) = result as "Task should have been aborted"
    future.resolve(Nil)
  })
  Nil
}
