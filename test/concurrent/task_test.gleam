import stardos/concurrent/future
import stardos/concurrent/task

// Test task spawning
pub fn task_spawn_test() -> Nil {
  let f = future.new(fn() { 100 })
  task.spawn(f)
  Nil
}

// Test abortable task creation and abort
pub fn task_abort_test() -> Nil {
  let f = future.new(fn() { 200 })
  let assert Ok(abortable_task) = task.spawn_abortable(f)
  task.abort(abortable_task)
  Nil
}
