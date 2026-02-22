import { to_milliseconds } from 'gleam:@gleam_time/gleam/time/duration'
import { type Future } from './future_ffi'
import {
  Stream$First,
  Stream$Continue,
  type First
} from 'gleam:@stardos/stardos/concurrent/stream'

export function sleep(duration): Future<undefined> {
  let timer: NodeJS.Timeout
  return {
    execute: () =>
      new Promise((res) => {
        timer = setTimeout(() => res(undefined), to_milliseconds(duration))
      }),
    cleanup: () => clearTimeout(timer)
  }
}

// todo figure out how to solve timing issue
// export function interval(duration): First {
//   const durationMs = to_milliseconds(duration)
//   let intervalTimer: NodeJS.Timeout
//   return Stream$First({
//     execute: () => {
//       intervalTimer = setIn
//       return new Promise((res) => {
//         timerCb = () => {
//           res(Stream$Continue(undefined))
//         }
//         if (intervalTimer === 0)
//           intervalTimer = setInterval(timerCb, durationMs)
//       })
//     },
//     cleanup: () => clearInterval(intervalTimer)
//   })
// }
