import stardos/concurrent/future.{type Future}

pub type Task(a)

pub type AbortableTask(a) {
  AbortableTask(task: Task(a), abort: fn() -> Nil)
}

pub type AbortableTaskError {
  /// The environment does not support abortable tasks.
  Unsupported
}

@external(javascript, "./task_ffi.mjs", "spawnTask")
pub fn spawn(future: Future(a)) -> Task(a)

pub fn spawn_abortable(
  future: Future(a),
) -> Result(AbortableTask(a), AbortableTaskError) {
  case spawn_abortable_internal(future) {
    Ok(#(task, abort)) -> Ok(AbortableTask(task:, abort:))
    Error(Nil) -> Error(Unsupported)
  }
}

@external(javascript, "./task_ffi.mjs", "spawnAbortableTask")
fn spawn_abortable_internal(
  future: Future(a),
) -> Result(#(Task(a), fn() -> Nil), Nil)
