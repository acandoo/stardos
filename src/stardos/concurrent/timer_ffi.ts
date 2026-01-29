import { to_milliseconds } from 'gleam:@gleam_time/gleam/time/duration'
import { type Future } from './future_ffi'
import {
  type FutureStream,
  FutureStream$FutureStream
} from 'gleam:@stardos/stardos/concurrent/stream'

export function sleep(duration): Future<undefined> {
  return () =>
    new Promise((res) =>
      setTimeout(() => res(undefined), to_milliseconds(duration))
    )
}

// todo figure out how to solve timing issue
export function interval(duration): FutureStream {
  return FutureStream$FutureStream(
    () =>
      new Promise((res) =>
        setTimeout(() => res(undefined), to_milliseconds(duration))
      )
  )
}
