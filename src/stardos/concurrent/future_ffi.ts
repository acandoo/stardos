export type Future<Result> = {
  execute: () => Promise<Result>
}

export function newFuture<Result>(compute: () => Result): Future<Result> {
  return {
    execute: async () => compute()
  }
}

export function awaitFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (PrevResult) => NewResult
): Future<NewResult> {
  return {
    execute: async () => {
      const result = await future.execute()
      return cb(result)
    }
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
    }
  }
}

export function flattenFuture<Result>(
  future: Future<Future<Result>>
): Future<Result> {
  return {
    execute: async () => {
      const innerFuture = await future.execute()
      return innerFuture.execute()
    }
  }
}
