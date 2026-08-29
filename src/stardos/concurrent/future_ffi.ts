import {
  List,
  List$Empty,
  List$NonEmpty,
  List$isNonEmpty,
  List$NonEmpty$first,
  List$NonEmpty$rest
} from 'gleam'

function listFromArray<T>(array: T[]): List<T> {
  return array
    .reverse()
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

export type Future<Result> = {
  execute: (signal?: AbortSignal) => {
    promise: Promise<Result>
    /**
     * Only executes on cancellation!
     * If you need cleanup to run at the end of success,
     * ensure that cleanup logic is synchronous,
     * does not have the ability to error, or
     * is otherwise wrapped in a try-catch block so
     * failure doesn't trigger a second cleanup.
     *
     * This callback does not have to be implemented
     * if the promise is appropriately cancelled by a passed-in AbortSignal.
     */
    cancel: (() => void) | undefined
  }
}

export function newFuture<Result>(compute: () => Result): Future<Result> {
  return {
    execute: () => ({
      // Compared to Promise.resolve(compute()), this schedules compute to be a microtask
      promise: new Promise((res) => res(compute())),
      cancel: undefined
    })
  }
}

export function resolveFuture<Result>(input: Result): Future<Result> {
  return {
    execute: () => ({ promise: Promise.resolve(input), cancel: undefined })
  }
}

export function awaitFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (arg0: PrevResult) => Future<NewResult>
): Future<NewResult> {
  return {
    execute: (signal) => {
      const futureInstance = future.execute(signal)
      let canceller = futureInstance.cancel
      return {
        promise: futureInstance.promise.then((value) => {
          const newFutureInstance = cb(value).execute(signal)
          canceller = newFutureInstance.cancel
          return newFutureInstance.promise
        }),
        cancel: () => canceller?.()
      }
    }
  }
}

export function mapFuture<NewResult, PrevResult>(
  future: Future<PrevResult>,
  cb: (arg0: PrevResult) => NewResult
): Future<NewResult> {
  return {
    execute: (signal) => {
      const futureInstance = future.execute(signal)
      return {
        promise: futureInstance.promise.then((result) => cb(result)),
        cancel: futureInstance.cancel
      }
    }
  }
}

export function joinFutures<Result1, Result2>(
  future1: Future<Result1>,
  future2: Future<Result2>
): Future<[Result1, Result2]> {
  return {
    execute: (signal) => {
      const future1Instance = future1.execute(signal)
      const future2Instance = future2.execute(signal)
      return {
        promise: Promise.all([
          future1Instance.promise,
          future2Instance.promise
        ]),
        cancel: () => {
          future1Instance.cancel?.()
          future2Instance.cancel?.()
        }
      }
    }
  }
}

export function firstFuture<T>(futures: List<Future<T>>): Future<T> {
  const futureArray = listToArray(futures)
  return {
    execute: (signal) => {
      const futureInstanceArray = futureArray.map((fut) => fut.execute(signal))
      const promiseArray = futureInstanceArray.map(({ promise }) => promise)
      return {
        promise: Promise.race(promiseArray),
        cancel: () => {
          futureInstanceArray.forEach(({ cancel }) => cancel?.())
        }
      }
    }
  }
}

export function allFutures<T>(futures: List<Future<T>>): Future<List<T>> {
  const futureArray = listToArray(futures)
  return {
    execute: (signal) => {
      const futureInstanceArray = futureArray.map((fut) => fut.execute(signal))
      const promiseArray = futureInstanceArray.map(({ promise }) => promise)
      return {
        promise: Promise.all(promiseArray).then(listFromArray),
        cancel: () => {
          futureInstanceArray.forEach(({ cancel }) => cancel?.())
        }
      }
    }
  }
}

export function flattenFuture<Result>(
  future: Future<Future<Result>>
): Future<Result> {
  return {
    execute: (signal) => {
      const outerFutureInstance = future.execute(signal)
      let canceller = outerFutureInstance.cancel
      return {
        promise: outerFutureInstance.promise.then((value) => {
          const innerFutureInstance = value.execute(signal)
          canceller = innerFutureInstance.cancel
          return innerFutureInstance.promise
        }),
        cancel: () => canceller?.()
      }
    }
  }
}
