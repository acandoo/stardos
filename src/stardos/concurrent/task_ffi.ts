import { type Future } from './future_ffi'

type Task = {
  // Unique identifier for the task, used to prevent equality between tasks.
  taskId: symbol
}

type AbortableTask = Task & {
  abortController: AbortController
}

export function spawnTask(future: Future<any>): Task {
  future.execute()
  return {
    taskId: Symbol()
  }
}

export function spawnAbortableTask(future: Future<any>): AbortableTask {
  const abortController = new AbortController()
  const { signal } = abortController

  // Note: The future's computation should ideally check the signal
  // periodically to see if it has been aborted, and handle it accordingly.
  new Promise((resolve, reject) => {
    signal.addEventListener('abort', () => {
      reject(new Error('Task aborted'))
    })
    future.execute().then(resolve)
  })

  return {
    taskId: Symbol(),
    abortController
  }
}

export function abortTask(task: AbortableTask): void {
  task.abortController.abort()
}
