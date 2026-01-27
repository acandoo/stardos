import stardos/concurrent/future.{type Future}

pub type Task

pub type AbortableTask

pub type AbortableTaskError {
  /// The environment does not support abortable tasks.
  Unsupported
}

@external(javascript, "./task_ffi.mjs", "spawnTask")
pub fn spawn(future: Future(a)) -> Task

@external(javascript, "./task_ffi.mjs", "spawnAbortableTask")
pub fn spawn_abortable(
  future: Future(a),
) -> Result(AbortableTask, AbortableTaskError)

@external(javascript, "./task_ffi.mjs", "abortTask")
pub fn abort(task: AbortableTask) -> Nil
