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

// Task<T> isn't directly a Promise<T> to prevent weird coercions with nested Promises from happening in code.
// For example, if you awaited a Future<Task<T>>, you would get T instead of Task<T>.
// In addition, the Promise needs to be exposed so that Promise rejections can be properly handled by supervisors.
export type Task<T> = {
  promise: Promise<T>
}

export function awaitTask<T, E>(
  task: Task<T>,
  cb: (input: T) => Future<E>
): Future<E> {
  return (signal) => task.promise.then((value) => cb(value)(signal))
}

export function spawnTask<T>(future: Future<T>): Task<T> {
  // I'm not *too* sure, but I don't think I need to add an AbortController for cancellation.
  // If a
  return {
    promise: future()
  }
}

export function spawnAbortableTask<T, E>(
  future: Future<T>,
  errorObject: E
): [Task<Result<T, E>>, () => void] {
  const abortController = new AbortController()
  const { signal } = abortController

  // Note: The future's computation should ideally check the signal
  // periodically to see if it has been aborted, and handle it accordingly.
  const task = {
    promise: new Promise((res, rej) => {
      const aborter = () => res(Result$Error(errorObject))
      signal.addEventListener('abort', aborter, { once: true })
      future(signal)
        .then((val) => {
          signal.removeEventListener('abort', aborter)
          res(Result$Ok(val))
        })
        .catch(rej)
    }) satisfies Promise<Result<T, E>>
  }

  return [task, () => abortController.abort()]
}
