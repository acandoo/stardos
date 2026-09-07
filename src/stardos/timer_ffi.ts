import { createFuture, type Future } from './concurrent/future_ffi'

// For these two functions, we don't use the DOM API of passing in an AbortSignal
// because it's not portable across all JS runtimes.

export function timeoutMs(durationMs: number): Future<undefined> {
  let timer: ReturnType<typeof setTimeout> | undefined
  return createFuture(
    () =>
      new Promise(
        (res) =>
          (timer = setTimeout(res, durationMs) as unknown as ReturnType<
            typeof setTimeout
          >)
      ),
    () => clearTimeout(timer)
  )
}

export function intervalMs(
  durationMs: number,
  callback: () => void
): Future<undefined> {
  let timer: ReturnType<typeof setInterval> | undefined
  return createFuture(
    () => new Promise(() => (timer = setInterval(callback, durationMs))),
    () => clearInterval(timer)
  )
}
