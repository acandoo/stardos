import {
  List,
  List$Empty,
  List$NonEmpty,
  List$isNonEmpty,
  List$NonEmpty$first,
  List$NonEmpty$rest
} from 'gleam'

import {
  type Either$,
  Either$Left,
  Either$Right
} from 'gleam:@gleither/gleither'

function listFromArray<T>(array: T[]): List<T> {
  return array
    .toReversed()
    .reduce((acc, val) => List$NonEmpty(val, acc), List$Empty<T>())
}

function listToArray<T>(list: List<T>): T[] {
  const newArray: T[] = []
  let listItem = list
  while (true) {
    if (List$isNonEmpty(listItem)) {
      newArray.push(List$NonEmpty$first(listItem)!)
      listItem = List$NonEmpty$rest(listItem)!
    } else {
      break
    }
  }
  return newArray
}

/**
 * If you're manually implementing a Future,
 * the returning promise MUST not reject upon receiving an abort signal.
 * Promise rejects are reserved for panics within Gleam.
 * In addition, futures are expected to deregister any event listeners they may have added within their Promise.
 * See createFuture for an example.
 */
export type Future<Result> = {
  (signal?: AbortSignal): Promise<Result>
}

// This can be used internally.
export function createFuture<Result>(
  execute: () => Promise<Result>,
  abort: () => void
): Future<Result> {
  return (signal) =>
    new Promise((res, rej) => {
      signal?.addEventListener('abort', abort, { once: true })
      execute()
        .then((val) => {
          signal?.removeEventListener('abort', abort)
          res(val)
        })
        .catch(rej)
    })
}

export function newFuture<Result>(compute: () => Result): Future<Result> {
  return async () => compute()
}

export function resolveFuture<Result>(input: Result): Future<Result> {
  return async () => input
}

export function awaitFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (arg0: PrevResult) => Future<NewResult>
): Future<NewResult> {
  return (signal) => future(signal).then((val) => cb(val)(signal))
}

export function mapFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (arg0: PrevResult) => NewResult
): Future<NewResult> {
  return (signal) => future(signal).then(cb)
}

export function selectFuture<Left, Right>(
  future1: Future<Left>,
  future2: Future<Right>
): Future<Either$<Left, Right>> {
  return (signal) =>
    new Promise((res, rej) => {
      future1(signal)
        .then((value) => res(Either$Left(value)))
        .catch(rej)
      future2(signal)
        .then((value) => res(Either$Right(value)))
        .catch(rej)
    })
}

export function memoFuture<T>(future: Future<T>): Future<T> {
  // When memoing a future, it's effectively running a "weak task" in the background.
  // For this "weak task":
  //   - When all of its subscriber tasks have aborted, it stops listening to the promise. and becomes dead without error.
  // 2. a panic primitive was used within the future chain. This propagates up normally.
  // When another task re-executes the memoed future, the future is respawned.
  // This behavior ensures that the lifetime of all execution can be supervised by the tasks the application creates.

  // This controller controls the lifetime of the single "weak task" instance.
  const abortController = new AbortController()

  let promise: Promise<T> | null = null
  let dependents = 0

  const instanceAborter = () => {
    if (--dependents === 0) abortController.abort()
  }

  return (signal) => {
    dependents++
    promise ??= new Promise((res, rej) => {
      let innerRes: typeof res | null = res
      let innerRej: typeof rej | null = rej
      future(abortController.signal)
        .then((val) => innerRes?.(val))
        // Case 2 abortion handling
        .catch((val) => innerRej?.(val))
      abortController.signal.addEventListener(
        'abort',
        () => {
          innerRes = null
          innerRej = null
          promise = null
        },
        { once: true }
      )
    })
    signal?.addEventListener('abort', instanceAborter, { once: true })
    return promise.then((val) => {
      dependents--
      signal?.removeEventListener('abort', instanceAborter)
      return val
    })
  }
}

export function joinFutures<Result1, Result2>(
  future1: Future<Result1>,
  future2: Future<Result2>
): Future<[Result1, Result2]> {
  return (signal) => Promise.all([future1(signal), future2(signal)])
}

export function firstFuture<T>(futures: List<Future<T>>): Future<T> {
  const futureArray = listToArray(futures)
  return (signal) => Promise.race(futureArray.map((fut) => fut(signal)))
}

export function allFutures<T>(futures: List<Future<T>>): Future<List<T>> {
  const futureArray = listToArray(futures)
  return (signal) =>
    Promise.all(futureArray.map((fut) => fut(signal))).then(listFromArray)
}

export function flattenFuture<Result>(
  future: Future<Future<Result>>
): Future<Result> {
  return (signal) => future(signal).then((innerFuture) => innerFuture(signal))
}
