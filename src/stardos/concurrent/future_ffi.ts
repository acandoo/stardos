import { List } from 'gleam'

export type Future<Result> = {
  (): Promise<Result>
}

export function newFuture<Result>(compute: () => Result): Future<Result> {
  return async () => compute()
}

export function resolveFuture<Result>(input: Result): Future<Result> {
  return async () => input
}

export function awaitFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (PrevResult) => Future<NewResult>
): Future<NewResult> {
  return async () => {
    const result = await future()
    return await cb(result)()
  }
}

export function joinFutures<Result1, Result2>(
  future1: Future<Result1>,
  future2: Future<Result2>
): Future<[Result1, Result2]> {
  return async () => {
    const [result1, result2] = await Promise.all([
      future1(),
      future2()
    ])
    return [result1, result2]
  }
}

export function firstFuture<T>(
  futures: List
): Future<T> {
  return async () => {
    return await Promise.race(
      futures.toArray().map((fut: Future<T>) => fut())
    )
  }
}

export function allFutures(futures: List): Future<List> {
  return async () => {
    const result = await Promise.all(
      futures.toArray().map((fut: Future<any>) => fut())
    )
    return List.fromArray(result)
  }
}

export function flattenFuture<Result>(
  future: Future<Future<Result>>
): Future<Result> {
  return async () => {
    const innerFuture = await future()
    return await innerFuture()
  }
}
