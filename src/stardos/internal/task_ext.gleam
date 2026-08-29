import stardos/concurrent/future.{type Future}
import stardos/concurrent/task.{type Task}

@external(javascript, "../concurrent/task_ffi.mjs", "spawnWeakTask")
pub fn spawn_weak(future: Future(a)) -> Result(Task(a), Nil)
