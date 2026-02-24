import {
  to_milliseconds,
  type empty as Duration
} from 'gleam:@gleam_time/gleam/time/duration'
import { type Future } from './future_ffi'
import {
  Stream$First,
  Stream$Continue,
  type First
} from 'gleam:@stardos/stardos/concurrent/stream'

export function sleepMs(durationMs: number): void {
  // Use Atomics.wait on a SharedArrayBuffer to block without busy-waiting.
  const sharedBuffer = new SharedArrayBuffer(4)
  const int32 = new Int32Array(sharedBuffer)
  Atomics.wait(int32, 0, 0, durationMs)
}

export function timeoutMs(durationMs: number): Future<undefined> {
  let timer: NodeJS.Timeout
  return {
    execute: () =>
      new Promise((res) => {
        timer = setTimeout(() => res(undefined), durationMs)
      }),
    cleanup: () => clearTimeout(timer)
  }
}

export function interval(duration: typeof Duration): First {
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
