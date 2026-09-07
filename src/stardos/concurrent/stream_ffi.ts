import {
  type Stream$,
  Stream$Continue,
  Stream$First
} from 'gleam:@stardos/stardos/internal/stream_base'
import { Future } from './future_ffi'

export function capture<Value, Return>(
  fun: (callback: (a: Value) => void) => Return
): [Stream$<Value>, Return] {
  // For each task at each index, either the value will be generated first or the task will reach the index's promise first.

  // We make a 2D array in case multiple tasks iterate through the resulting stream
  const resolvers: Array<Array<(a: Stream$<Value>) => void>> = []
  const values: Value[] = []

  const getValue = (index: number): Promise<Stream$<Value>> =>
    new Promise((res) => {
      if (index in values) {
        res(Stream$Continue(values[index], () => getValue(index + 1)))
      } else {
        resolvers[index]?.push(res)
        resolvers[index] ??= [res]
      }
    })

  // Should be in line with values.length
  let indexToBeGenerated = 0
  const ret = fun((value) => {
    values[indexToBeGenerated] = value
    const index = indexToBeGenerated
    indexToBeGenerated++

    const resolverList = resolvers[index]
    if (resolverList) {
      for (const resolver of resolverList) {
        resolver(Stream$Continue(value, () => getValue(indexToBeGenerated)))
      }
      resolvers[index] = []
    }
  })

  return [
    Stream$First((() => getValue(0)) satisfies Future<Stream$<Value>>),
    ret
  ]
}
