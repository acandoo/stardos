/**
 * Tasks' containing promises should **never** reject unless a task it depends on is cancelled.
 * This is thanks to Gleam's type system on the upper level.
 * This would only be violated by custom task FFIs in other packages.
 *
 * Cancels only propagate upstream, except for weak tasks downstream,
 * which get cancelled by the last depending task if all tasks upstream are cancelled.
 * This includes weak tasks, since they're ultimately kept alive by upstream regular tasks.
 */
import { type Future } from './future_ffi'
import { type Result, Result$Error, Result$Ok } from 'gleam'
import { AbortableTaskError$Unsupported } from 'gleam:@stardos/stardos/concurrent/task'

export type Task<T> = RegularTask<T> | WeakTask<T>
type RegularTask<T> = {
  promise: Promise<T>
}
type WeakTask<T> = RegularTask<T> & {
  dependents: number
  aborter: AbortController
}

const isWeakTask = <T>(task: Task<T>): task is WeakTask<T> =>
  'dependents' in task

export function awaitTask<T, E>(
  task: Task<T>,
  cb: (input: T) => Future<E>
): Future<E> {
  let isInternalTaskError = false
  return {
    execute: async () => {
      if (isWeakTask(task)) task.dependents++
      isInternalTaskError = true
      const val = await task.promise
      isInternalTaskError = false
      if (isWeakTask(task)) task.dependents--
      return await cb(val).execute()
    },
    // Cleanup can either be triggered by the child task or parent task.
    // If triggered by the parent task AND dealing with a weak task with no other dependents, then
    // cleanup is the responsibility of this scope.
    cleanup: () => {
      if (isWeakTask(task)) {
        task.dependents--
        if (task.dependents === 0 && isInternalTaskError) task.aborter.abort()
      }
    }
  }
}

export function spawnWeakTask<T>(
  future: Future<T>
): Result<WeakTask<T>, undefined> {
  if (!globalThis.AbortController) return Result$Error(undefined)
  const abortController = new AbortController()
  const { signal } = abortController
  let isAborted = false
  return Result$Ok({
    promise: new Promise((res, rej) => {
      signal.addEventListener(
        'abort',
        () => {
          isAborted = true
          future.cleanup?.()
          rej(new Error('Task aborted'))
        },
        { once: true }
      )
      future
        .execute()
        .then(res)
        .catch(() => {
          if (!isAborted) {
            future.cleanup?.()
          }
        })
    }),
    dependents: 0,
    aborter: abortController
  })
}

export function spawnTask<T>(future: Future<T>): Task<T> {
  // Note: we want the event loop to stay while the Promise is running,
  // so a setInterval is used to keep it alive.
  const interval = setInterval(() => {})

  return {
    promise: future
      .execute()
      // An error will be thrown if a Task downstream is prematurely cancelled (i.e. rejected).
      // Similarly, this also needs to throw to depening Tasks upstream.
      .catch((e) => {
        future.cleanup?.()
        throw e
      })
      .finally(() => {
        clearInterval(interval)
      })
  }
}

export function spawnAbortableTask<T>(
  future: Future<T>
): Result<[Task<T>, () => void], Error> {
  if (!globalThis.AbortController)
    return Result$Error(AbortableTaskError$Unsupported())
  const abortController = new AbortController()
  const { signal } = abortController

  // Note: The future's computation should ideally check the signal
  // periodically to see if it has been aborted, and handle it accordingly.
  let isAborted = false
  const task = {
    promise: new Promise((res, rej) => {
      signal.addEventListener(
        'abort',
        () => {
          isAborted = true
          future.cleanup?.()
          rej(new Error('Task aborted'))
        },
        { once: true }
      )
      future.execute().finally(() => {
        if (!isAborted) {
          future.cleanup?.()
        }
        res(null)
      })
    })
  }

  return Result$Ok([task as Task<T>, () => abortController.abort()])
}
