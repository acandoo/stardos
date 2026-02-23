import { type Future } from './future_ffi'
import { type Result, Result$Error, Result$Ok } from 'gleam'
import { AbortableTaskError$Unsupported } from 'gleam:@stardos/stardos/concurrent/task'

export type Task<T> = {
  promise: Promise<T>
}

export type AbortableTask<T> = Task<T | Error> & {
  abortController: AbortController
}

export function spawnTask<T>(future: Future<T>): Task<T> {
  // Note: we want the event loop to stay while the Promise is running,
  // so the executor is wrapped and a setInterval is used to keep it alive.
  return {
    promise: new Promise(() => {
      const interval = setInterval(() => {})
      future.execute().finally(() => {
        clearInterval(interval)
        future.cleanup?.()
      })
    })
  }
}

export function spawnAbortableTask<T>(future: Future<T>): Result {
  if (!globalThis.AbortController)
    return Result$Error(AbortableTaskError$Unsupported())
  const abortController = new AbortController()
  const { signal } = abortController

  // Note: The future's computation should ideally check the signal
  // periodically to see if it has been aborted, and handle it accordingly.
  let isAborted = false
  const task = {
    promise: new Promise((resolve) => {
      signal.addEventListener('abort', () => {
        isAborted = true
        future.cleanup?.()
        resolve(new Error('Task aborted'))
      })
      future.execute().finally(() => {
        if (!isAborted) {
          future.cleanup?.()
        }
        resolve(null)
      })
    }),
    abortController
  }

  return Result$Ok(task as AbortableTask<T>)
}

export function abortTask<T>(task: AbortableTask<T>): void {
  task.abortController.abort()
}
