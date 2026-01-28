//// The `io/file` module provides functions for interacting with the OS filesystem.

import gleam/option.{type Option}
import stardos/io.{type IoError, type IoPermissions, type WriteMode}

pub type FileHandle

pub type FileRef {
  FilePath(path: String)
  Fd(path: String)
}

pub type ExistMode {
  MustExist
  MustNotExist
  CreateIfNotExist(truncate: Bool)
}

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
pub fn open(
  from ref: FileRef,
  given permissions: IoPermissions,
  on_exist exist_mode: ExistMode,
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

pub fn overwrite(
  in path: String,
  with data: BitArray,
  then callback: fn(Result(Nil, IoError)) -> Nil,
) -> Nil {
  use file <- open(
    FilePath(path),
    io.WriteOnly(io.Absolute),
    CreateIfNotExist(truncate: False),
  )
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
