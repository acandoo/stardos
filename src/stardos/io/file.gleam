//// The `io/file` module provides functions for interacting with the OS filesystem.
//// By default, all file operations are synchronous unless prefixed with `async_`, in which case
//// they are asynchronous and non-blocking.

import stardos/io.{type IoError, type IoPermissions, type WriteMode}

/// A reference to a file, either by its path or file descriptor.
pub type FileRef {
  /// A path to a file on the filesystem.
  FilePath(path: String)
  /// A file descriptor representing an open file.
  Fd(fd: Int)
}

pub type ExistMode {
  /// The file must exist. Otheriwse, an `io.Enoent` error occurs.
  MustExist
  /// The file must not exist. Otherwise, an `io.Eexist` error occurs.
  MustNotExist
  /// If the file does not exist, it is created. If it does exist, it is opened as normal.
  CreateIfNotExist(
    /// Whether to overwrite any existing data.
    truncate: Bool,
  )
}

/// Opens the file at the specified path. An exception `io.Enoent` occurs if the file does not exist.
/// An error on open is passed to the callback function, while an error on close is returned.
/// 
/// If you want to open files asynchronously, use `file.async_open()`.
/// If you want the file to be created *and* overwrite any existing data, use `file.new()`.
/// 
/// ## Example
/// 
/// ```gleam
/// use project_config_file <- file.open(
///   from: FilePath("./config.toml"),
///   given: io.ReadOnly,
///   on_exist: file.MustExist,
/// )
/// let config = case project_config_file {
///   Ok(a) -> Ok(process_config(a))
///   Error(io.Enoent) -> Error("No project found")
///   _ -> Error("Unknown error occurred")
/// }
/// ```
/// 
pub fn open(
  from ref: FileRef,
  given permissions: IoPermissions,
  on_exist exist_mode: ExistMode,
  then callback: fn(Result(io.IoDevice, IoError)) -> Nil,
) -> Result(Nil, IoError) {
  let file_result = open_unsafe(ref, permissions, exist_mode)
  callback(file_result)
  case file_result {
    Ok(file) -> close_unsafe(file)
    Error(_) -> Ok(Nil)
  }
}

@external(javascript, "./file_ffi.mjs", "openUnsafe")
fn open_unsafe(
  from ref: FileRef,
  given permissions: IoPermissions,
  on_exist exist_mode: ExistMode,
) -> Result(io.IoDevice, IoError)

@external(javascript, "./file_ffi.mjs", "closeUnsafe")
fn close_unsafe(file: io.IoDevice) -> Result(Nil, IoError)

/// Creates a new file at the specified path. If the file exists, its data is overwritten.
/// The file is opened with write-only permissions.
/// 
/// If you want to create files asynchronously, use `file.async_new()`.
/// If you want to handle existing files on the filesystem, use `file.open()`.
/// 
/// ## Example
/// 
/// ```gleam
/// use log_file <- file.new(
///   at: "./logs/app.log",
///   given: file.Append,
/// )
/// 
pub fn new(
  at path: String,
  given write_mode: WriteMode,
  then callback: fn(Result(io.IoDevice, IoError)) -> Nil,
) -> Result(Nil, IoError) {
  open(
    FilePath(path),
    io.WriteOnly(write_mode),
    CreateIfNotExist(truncate: True),
    callback,
  )
}

@external(javascript, "./file_ffi.mjs", "write")
pub fn write(to file: FileRef, with data: BitArray) -> Result(Nil, IoError)

@external(javascript, "./file_ffi.mjs", "read")
pub fn read(
  from file: FileRef,
  then callback: fn(Result(BitArray, IoError)) -> Nil,
) -> Nil
