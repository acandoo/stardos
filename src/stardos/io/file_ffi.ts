import { readFile, writeFile } from 'node:fs/promises'
import { type Future } from '../concurrent/future_ffi'
import { Result$Error, Result$Ok, type Result } from 'gleam'
import { BitArray$BitArray, type BitArray } from 'gleam'

type Path = {
  path: string
}

function rawBytes(data: BitArray): Uint8Array {
  return data.rawBuffer
}

function errorToCode(error: unknown): string {
  if (error instanceof Error) {
    return (error as NodeJS.ErrnoException).code ?? error.message
  }
  return String(error)
}

function readFileFuture(file: Path): Future<Result<BitArray, string>> {
  return async () => {
    try {
      return Result$Ok(BitArray$BitArray(await readFile(file.path)))
    } catch (error) {
      return Result$Error(errorToCode(error))
    }
  }
}

export function readAsync(file: Path): Future<Result<BitArray, string>> {
  return readFileFuture(file)
}

export function read(
  file: Path,
  callback: (result: Result<BitArray, string>) => void
): void {
  readFileFuture(file)().then(callback)
}

export function write(
  file: Path,
  data: BitArray
): Future<Result<undefined, string>> {
  return async () => {
    try {
      await writeFile(file.path, rawBytes(data))
      return Result$Ok(undefined)
    } catch (error) {
      return Result$Error(errorToCode(error))
    }
  }
}
