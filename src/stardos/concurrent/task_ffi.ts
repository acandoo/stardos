import { type Future } from './future_ffi'
import { type Result, Result$Error, Result$Ok } from 'gleam'
import { AbortableTaskError$Unsupported } from 'gleam:@stardos/stardos/concurrent/task'

type Task = {
  // Unique identifier for the task, used to prevent equality between tasks.
  taskId: symbol
}

type AbortableTask = Task & {
  abortController: AbortController
}

export function spawnTask(future: Future<any>): Task {
  // Note: we want the event loop to stay while the Promise is running,
  // so a setInterval is used to keep it alive.
  new Promise(() => {
    const interval = setInterval(() => {})
    future().finally(() => clearInterval(interval))
  })
  return {
    taskId: Symbol()
  }
}

export function spawnAbortableTask(future: Future<any>): Result {
  if (!globalThis.AbortController)
    return Result$Error(AbortableTaskError$Unsupported())
  const abortController = new AbortController()
  const { signal } = abortController

  // Note: The future's computation should ideally check the signal
  // periodically to see if it has been aborted, and handle it accordingly.
  new Promise((resolve, reject) => {
    signal.addEventListener('abort', () => {
      reject(new Error('Task aborted'))
    })
    future().then(resolve)
  })

  return Result$Ok({
    taskId: Symbol(),
    abortController
  } as AbortableTask)
}

export function abortTask(task: AbortableTask): void {
  task.abortController.abort()
}
