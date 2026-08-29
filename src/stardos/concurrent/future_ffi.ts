import { List } from 'gleam'

export type Future<Result> = {
  execute: () => Promise<Result>
  /**
   * Only executes on cancellation!
   * If you need cleanup to run at the end of success,
   * ensure that cleanup logic is synchronous,
   * does not have the ability to error, or
   * is otherwise wrapped in a try-catch block so
   * failure doesn't trigger a second cleanup.
   */
  cleanup: (() => void) | undefined
}

export function newFuture<Result>(compute: () => Result): Future<Result> {
  return {
    execute: async () => compute(),
    cleanup: undefined
  }
}

export function resolveFuture<Result>(input: Result): Future<Result> {
  return {
    execute: async () => input,
    cleanup: undefined
  }
}

export function awaitFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (arg0: PrevResult) => Future<NewResult>
): Future<NewResult> {
  return {
    execute: async () => {
      const result = await future.execute()
      return await cb(result).execute()
    },
    cleanup: future.cleanup
  }
}

export function mapFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (arg0: PrevResult) => NewResult
): Future<NewResult> {
  return {
    execute: async () => {
      const result = await future.execute()
      return cb(result)
    },
    cleanup: future.cleanup
  }
}

export function joinFutures<Result1, Result2>(
  future1: Future<Result1>,
  future2: Future<Result2>
): Future<[Result1, Result2]> {
  return {
    execute: async () => {
      const [result1, result2] = await Promise.all([
        future1.execute(),
        future2.execute()
      ])
      return [result1, result2]
    },
    cleanup: () => {
      future1.cleanup?.()
      future2.cleanup?.()
    }
  }
}

export function firstFuture<T>(futures: List<Future<T>>): Future<T> {
  return {
    execute: async () => {
      return await Promise.race(
        futures.toArray().map((fut: Future<T>) => fut.execute())
      )
    },
    cleanup: () => {
      futures.toArray().forEach((fut: Future<T>) => fut.cleanup?.())
    }
  }
}

export function allFutures<T>(futures: List<Future<T>>): Future<List<T>> {
  return {
    execute: async () => {
      const result = await Promise.all(
        futures.toArray().map((fut: Future<T>) => fut.execute())
      )
      return List.fromArray(result)
    },
    cleanup: undefined
  }
}

export function flattenFuture<Result>(
  future: Future<Future<Result>>
): Future<Result> {
  return {
    execute: async () => {
      const innerFuture = await future.execute()
      return await innerFuture.execute()
    },
    cleanup: future.cleanup
  }
}
