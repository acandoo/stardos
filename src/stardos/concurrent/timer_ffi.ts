import { to_milliseconds } from 'gleam:@gleam_time/gleam/time/duration'
import { type Future } from './future_ffi'
import {
  Stream$First,
  Stream$Continue,
  type First
} from 'gleam:@stardos/stardos/concurrent/stream'

export function sleep(duration): void {
  const durationMs = to_milliseconds(duration)
  const start = Date.now()
  while (Date.now() - start < durationMs) {
    // Busy wait
  }
}

export function timeout(duration): Future<undefined> {
  let timer: NodeJS.Timeout
  return {
    execute: () =>
      new Promise((res) => {
        timer = setTimeout(() => res(undefined), to_milliseconds(duration))
      }),
    cleanup: () => clearTimeout(timer)
  }
}

export function interval(duration): First {
  const durationMs = to_milliseconds(duration)
  let timerCb: () => void
  let intervalTimer: NodeJS.Timeout

  const intervalLoop = () =>
    Stream$Continue(undefined, {
      execute: () =>
        new Promise((res) => {
          timerCb = () => {
            res(intervalLoop())
          }
        })
    })

  return Stream$First({
    execute: () =>
      new Promise((res) => {
        timerCb = () => {
          res(intervalLoop())
        }
        intervalTimer = setInterval(() => timerCb(), durationMs)
      }),
    cleanup: () => clearInterval(intervalTimer)
  })
}
