import { Future } from './concurrent/future_ffi'
import { Result$Ok, Result$Error, type Result } from 'gleam'
import { type BitArray, BitArray$BitArray } from 'gleam'

type InternalPosition = number | 'start' | 'end'

// r/w/a types

export type Reader = {
  readAll: () => Promise<Uint8Array>
  read: (
    position: InternalPosition,
    length: number | null
  ) => Promise<Uint8Array>
}

export type Writer = {
  write: (buffer: Uint8Array, position: InternalPosition) => Promise<void>
}

export type Appender = {
  append: (buffer: Uint8Array) => Promise<void>
}

// stdio devices

export function stdout(): Appender {
  return {
    append: (buffer) =>
      new Promise((resolve, reject) => {
        process.stdout.write(buffer, (err) => {
          if (err) reject(err)
          else resolve()
        })
      })
  }
}

// utils

function errorToCode(e: unknown): string {
  if (e instanceof Error) {
    return (e as NodeJS.ErrnoException).code ?? e.message
  }
  return (e as object).toString?.() ?? 'UNKNOWN_ERROR'
}

// io operations

export function readAbsolute(
  device: Reader,
  position: number,
  length: number | null
): Future<Result<BitArray, string>> {
  return {
    execute: async () => {
      try {
        const buffer = await device.read(position, length)
        return Result$Ok(BitArray$BitArray(buffer))
      } catch (e) {
        return Result$Error(errorToCode(e))
      }
    },
    cleanup: undefined
  }
}

export function readEnd(
  device: Reader,
  length: number | null
): Future<Result<BitArray, string>> {
  return {
    execute: async () => {
      try {
        return Result$Ok(await device.read('end', length))
      } catch (e) {
        return Result$Error(errorToCode(e))
      }
    },
    cleanup: undefined
  }
}

export function readStart(
  device: Reader,
  length: number | null
): Future<Result<BitArray, string>> {
  return {
    execute: async () => {
      try {
        return Result$Ok(await device.read('start', length))
      } catch (e) {
        return Result$Error(errorToCode(e))
      }
    },
    cleanup: undefined
  }
}

export function readAll(reader: Reader): Future<Result<BitArray, string>> {
  return {
    execute: async () => {
      try {
        return Result$Ok(await reader.readAll())
      } catch (e) {
        return Result$Error(errorToCode(e))
      }
    },
    cleanup: undefined
  }
}
