import { to_milliseconds } from 'gleam:@gleam_time/gleam/time/duration'
import { type Future } from './future_ffi'
import {
  type FutureStream,
  type Next,
  FutureStream$FutureStream,
  Step$Next
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
export function interval(duration): FutureStream {
  const durationMs = to_milliseconds(duration)
  let intervalTimer: NodeJS.Timeout | number = 0
  return FutureStream$FutureStream(() => {
    // The input callback to the FutureStream constructor executes
    // immediately and is not deferred until the FutureStream is awaited,
    // so the timer has to be created inside the execute function.
    let timerCb: () => void
    return {
      execute: () =>
        new Promise((res) => {
          timerCb = () => {
            res(Step$Next(undefined))
          }
          if (intervalTimer === 0)
            intervalTimer = setInterval(timerCb, durationMs)
        }),
      cleanup: () => clearInterval(intervalTimer)
    } as Future<Next>
  })
}
