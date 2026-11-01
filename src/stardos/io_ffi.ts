import { createFuture, Future } from './concurrent/future_ffi'
import { Result$Ok, Result$Error, type Result } from 'gleam'
import { type BitArray, BitArray$BitArray, BitArray$BitArray$data } from 'gleam'
import {
  type Option$,
  Option$isSome,
  Option$Some$0
} from 'gleam:@gleam_stdlib/gleam/option'

type InternalPosition = number | 'start' | 'end'

// r/w/a types

export type Reader = {
  readAll: (signal?: AbortSignal) => Promise<Uint8Array>
  read: (
    position: InternalPosition,
    length: number | null,
    signal?: AbortSignal
  ) => Promise<Uint8Array>
}

export type Writer = {
  write: (
    buffer: Uint8Array,
    position: InternalPosition,
    signal?: AbortSignal
  ) => Promise<void>
}

export type Appender = {
  append: (buffer: Uint8Array, signal?: AbortSignal) => Promise<void>
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

export function stderr() {}
export function stdin() {}

// utils

function errorToCode(e: unknown): string {
  if (e instanceof Error) {
    return (e as NodeJS.ErrnoException).code ?? e.message
  }
  return (e as object).toString?.() ?? 'UNKNOWN_ERROR'
}

function rawBytes(data: BitArray): Uint8Array {
  const dataview = BitArray$BitArray$data(data)
  return new Uint8Array(
    dataview.buffer,
    dataview.byteOffset,
    dataview.byteLength
  )
}

// io operations

export function readAbsolute(
  device: Reader,
  position: number,
  length: Option$<number>
): Future<Result<BitArray, string>> {
  return async () => {
    try {
      const buffer = await device.read(position, length)
      return Result$Ok(BitArray$BitArray(buffer))
    } catch (e) {
      return Result$Error(errorToCode(e))
    }
  }
}

export function readEnd(
  device: Reader,
  length: Option$<number>
): Future<Result<BitArray, string>> {
  let lengthNum: number | null = null
  if (Option$isSome(length)) lengthNum = Option$Some$0(length) as number
  return readAt(device, lengthNum)
}

export function readStart(
  device: Reader,
  length: number | null
): Future<Result<BitArray, string>> {
  return readAt(device)
}

export function readAll(reader: Reader): Future<Result<BitArray, string>> {
  return async (signal) => {
    try {
      return Result$Ok(await reader.readAll(signal))
    } catch (e) {
      return Result$Error(errorToCode(e))
    }
  }
}

function readAt(
  device: Reader,
  position: InternalPosition
): Future<Result<undefined, string>> {
  return async (signal) => {
    try {
      return Result$Ok(await device.read(position, length, signal))
    } catch (e) {
      return Result$Error(errorToCode(e))
    }
  }
}

export function writeAbsolute(
  device: Writer,
  data: BitArray,
  position: number
): Future<Result<undefined, string>> {
  return writeAt(device, data, position)
}

export function writeEnd(
  device: Writer,
  data: BitArray
): Future<Result<undefined, string>> {
  return writeAt(device, data, 'end')
}

export function writeStart(
  device: Writer,
  data: BitArray
): Future<Result<undefined, string>> {
  return writeAt(device, data, 'start')
}

function writeAt(
  device: Writer,
  data: BitArray,
  position: InternalPosition
): Future<Result<undefined, string>> {
  return async (signal) => {
    try {
      await device.write(rawBytes(data), position, signal)
      return Result$Ok(undefined)
    } catch (e) {
      return Result$Error(errorToCode(e))
    }
  }
}

export function append(
  device: Appender,
  data: BitArray
): Future<Result<undefined, string>> {
  return async () => {
    try {
      await device.append(rawBytes(data))
      return Result$Ok(undefined)
    } catch (e) {
      return Result$Error(errorToCode(e))
    }
  }
}

export function stream(_device: Reader, _maxChunkSize: number | null): unknown {
  throw new Error('stream is not implemented')
}
