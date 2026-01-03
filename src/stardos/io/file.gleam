//// The `io/file` module provides functions for interacting with the OS filesystem.

import gleam/option.{type Option}
import stardos/io.{type IoError, type IoPermissions, type WriteMode}

pub type FileHandle

// In order to keep the function signatures and types simple, there are different functions for opening
// files that have subtle differences on truncating and creating the file.

/// Opens the file at the specified path. An exception `io.Enoent` occurs if the file does not exist.
/// 
/// If you want the file to be created if it does not exist, use `file.open()`.
/// If you want the file to be created *and* overwrite any existing data, use `file.new()`.
/// 
/// ## Examples
/// 
/// ```gleam
/// use project_config_file <- file.at_path("./config.toml", ReadOnly)
/// let config = case project_config_file {
///   Ok(a) -> Ok(process_config(a))
///   Error(io.Enoent) -> Error("No project found")
///   _ -> Error("Unknown error occurred")
/// }
/// ```
@external(javascript, "./file_ffi.mjs", "atPath")
pub fn at_path(
  path: String,
  given permissions: IoPermissions,
  then callback: fn(Result(FileHandle, IoError)) -> Nil,
) -> Nil

/// Opens the file at the specified path. If the file does not exist, a new one is created.
/// 
/// If you want an exception to occur with no file, use `file.at_path()`.
/// If you want the file to be created *and* overwrite any existing data, use `file.new()`.
@external(javascript, "./file_ffi.mjs", "open")
pub fn open(
  path: String,
  given permissions: IoPermissions,
  then callback: fn(Result(FileHandle, IoError)) -> Nil,
) -> Nil

/// Creates a new file at the specified path. If the file exists, its data is overwritten.
/// The file is opened with write-only permissions.
/// 
/// If you want an exception to occur with no file *and* for no data to be overwritten, use `file.at_path()`.
/// If you want the file to be created *and* overwrite any existing data, use `file.new()`.
@external(javascript, "./file_ffi.mjs", "newFile")
pub fn new(
  at path: String,
  given write_mode: WriteMode,
  then callback: fn(Result(FileHandle, IoError)) -> Nil,
) -> Nil

@external(javascript, "./file_ffi.mjs", "write")
pub fn write(
  to file: FileHandle,
  with data: BitArray,
  at position: Option(Int),
  then callback: fn(Result(Nil, IoError)) -> Nil,
) -> Nil

pub fn write_over_file(
  in path: String,
  with data: BitArray,
  then callback: fn(Result(Nil, IoError)) -> Nil,
) -> Nil {
  use file <- at_path(path, io.WriteOnly(io.Absolute))
  case file {
    Ok(a) -> write(to: a, with: data, at: option.None, then: callback)
    Error(a) -> callback(Error(a))
  }
}

@external(javascript, "./file_ffi.mjs", "read")
pub fn read(
  from file: FileHandle,
  then callback: fn(Result(BitArray, IoError)) -> Nil,
) -> Nil
