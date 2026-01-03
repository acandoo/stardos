import { BitArray$BitArray, Result$Ok, Result$Error } from '../../gleam.mjs'
import {
  Option$isNone,
  Option$Some$0
} from '../../../gleam_stdlib/gleam/option.mjs'
import {
  FileOpenPermissions$isReadOnly,
  FileOpenPermissions$isWriteOnly,
  FileOpenPermissions$isReadWrite
} from './file.mjs'
import fs from 'node:fs/promises'

const { O_RDONLY, O_WRONLY, O_RDWR, O_CREAT, O_TRUNC } = fs.constants

export async function atPath(path, flags, callback) {
  // argument parsing
  let newFlags
  if (FileOpenPermissions$isReadOnly(flags)) newFlags = O_RDONLY
  if (FileOpenPermissions$isWriteOnly(flags)) newFlags = O_WRONLY
  if (FileOpenPermissions$isReadWrite(flags)) newFlags = O_RDWR

  let file
  try {
    file = fs.open()
  } catch (err) {}
}

/**
 *
 * @param {import('node:fs/promises').FileHandle} file
 * @param {*} data
 * @param {*} callback
 */
export function write(file, data, callback) {
  file.writeFile(data.rawBuffer).then(callback, callback)
}
