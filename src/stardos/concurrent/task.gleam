import stardos/concurrent/future.{type Future}

pub type Task(a)

pub type AbortableTask(a) {
  AbortableTask(task: Task(a), abort: fn() -> Nil)
}

pub type AbortableTaskError {
  /// The task was prematurely aborted by the user.
  Aborted
}

@external(javascript, "./task_ffi.mjs", "awaitTask")
pub fn await(task: Task(a), then cb: fn(a) -> Future(b)) -> Future(b)

@external(javascript, "./task_ffi.mjs", "spawnTask")
pub fn spawn(future: Future(a)) -> Task(a)

pub fn spawn_abortable(
  future: Future(a),
) -> AbortableTask(Result(a, AbortableTaskError)) {
  let #(task, abort) = spawn_abortable_internal(future, Aborted)
  AbortableTask(task:, abort:)
}

@external(javascript, "./task_ffi.mjs", "spawnAbortableTask")
fn spawn_abortable_internal(
  future: Future(a),
  error_object: AbortableTaskError,
) -> #(Task(Result(a, AbortableTaskError)), fn() -> Nil)
