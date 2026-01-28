import { BitArray$BitArray, Result$Ok, Result$Error } from 'gleam'
import { Option$isNone, Option$Some$0 } from 'gleam:@gleam_stdlib/gleam/option'
import {
  IoPermissions$isReadOnly,
  IoPermissions$isWriteOnly,
  IoPermissions$isReadWrite
} from 'gleam:@stardos/stardos/io'
import fs from 'node:fs/promises'

const { O_RDONLY, O_WRONLY, O_RDWR, O_CREAT, O_TRUNC } = fs.constants

export async function atPath(path, flags, callback) {
  // argument parsing
  let newFlags
  if (IoPermissions$isReadOnly(flags)) newFlags = O_RDONLY
  if (IoPermissions$isWriteOnly(flags)) newFlags = O_WRONLY
  if (IoPermissions$isReadWrite(flags)) newFlags = O_RDWR

  let file
  try {
    file = null // fs.open()
  } catch (err) {}
}

export function write(file, data, callback) {
  file.writeFile(data.rawBuffer).then(callback, callback)
}
