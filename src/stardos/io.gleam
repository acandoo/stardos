//// The `io` module provides a unified interface for performing input and output operations across different platforms,
//// including file I/O, standard input/output, and error handling.
//// 
//// # I/O Devices
//// 
//// You may notice that there are four different types of I/O devices: `Reader`, `Scanner`, `Writer`, and `Appender`.
//// These represent different capabilities of I/O devices:
//// 
//// - `Reader`: Can read data from the device at a specific position.
//// - `Scanner`: Can read data sequentially from the device, maintaining an internal position.
//// - `Writer`: Can write data to the device at a specific position.
//// - `Appender`: Can write data to the end of the device, regardless of its current position.
////
//// This is due to different I/O devices having different capabilities. For example, a file can be read from and
//// written to at specific positions, while standard output can only be written to sequentially. By categorizing
//// I/O devices into these types, we can provide a more accurate and efficient interface for performing I/O operations.

import gleam/io
import gleam/option.{type Option}
import stardos/concurrent/future.{type Future}
import stardos/concurrent/stream.{type Stream}

/// Represents a POSIX error code returned by I/O operations.
pub type PosixError {
  /// Permission denied.
  Eacces
  /// Resource temporarily unavailable.
  Eagain
  /// Bad file descriptor.
  Ebadf
  /// Bad message.
  Ebadmsg
  /// Device or resource busy.
  Ebusy
  /// Resource deadlock avoided.
  Edeadlk
  /// Resource deadlock avoided (alias for `Edeadlk`).
  Edeadlock
  /// Disk quota exceeded.
  Edquot
  /// File exists.
  Eexist
  /// Bad address.
  Efault
  /// File too large.
  Efbig
  /// Inappropriate file type or format.
  Eftype
  /// Interrupted system call.
  Eintr
  /// Invalid argument.
  Einval
  /// Input/output error.
  Eio
  /// Is a directory.
  Eisdir
  /// Too many levels of symbolic links.
  Eloop
  /// Too many open files.
  Emfile
  /// Too many links.
  Emlink
  /// Multihop attempted.
  Emultihop
  /// File name too long.
  Enametoolong
  /// Too many open files in system.
  Enfile
  /// No buffer space available.
  Enobufs
  /// No such device.
  Enodev
  /// No locks available.
  Enolck
  /// Link has been severed.
  Enolink
  /// No such file or directory.
  Enoent
  /// Cannot allocate memory.
  Enomem
  /// No space left on device.
  Enospc
  /// No STREAM resources.
  Enosr
  /// Not a STREAM.
  Enostr
  /// Function not implemented.
  Enosys
  /// Block device required.
  Enotblk
  /// Not a directory.
  Enotdir
  /// Operation not supported.
  Enotsup
  /// No such device or address.
  Enxio
  /// Operation not supported on socket.
  Eopnotsupp
  /// Value too large for defined data type.
  Eoverflow
  /// Operation not permitted.
  Eperm
  /// Broken pipe.
  Epipe
  /// Result too large.
  Erange
  /// Read-only file system.
  Erofs
  /// Illegal seek.
  Espipe
  /// No such process.
  Esrch
  /// Stale file handle.
  Estale
  /// Text file busy.
  Etxtbsy
  /// Cross-device link.
  Exdev
}

pub fn posix_to_string(error: PosixError) -> String {
  case error {
    Eacces -> "EACCES"
    Eagain -> "EAGAIN"
    Ebadf -> "EBADF"
    Ebadmsg -> "EBADMSG"
    Ebusy -> "EBUSY"
    Edeadlk -> "EDEADLK"
    Edeadlock -> "EDEADLOCK"
    Edquot -> "EDQUOT"
    Eexist -> "EEXIST"
    Efault -> "EFAULT"
    Efbig -> "EFBIG"
    Eftype -> "EFTYPE"
    Eintr -> "EINTR"
    Einval -> "EINVAL"
    Eio -> "EIO"
    Eisdir -> "EISDIR"
    Eloop -> "ELOOP"
    Emfile -> "EMFILE"
    Emlink -> "EMLINK"
    Emultihop -> "EMULTIHOP"
    Enametoolong -> "ENAMETOOLONG"
    Enfile -> "ENFILE"
    Enobufs -> "ENOBUFS"
    Enodev -> "ENODEV"
    Enolck -> "ENOLCK"
    Enolink -> "ENOLINK"
    Enoent -> "ENOENT"
    Enomem -> "ENOMEM"
    Enospc -> "ENOSPC"
    Enosr -> "ENOSR"
    Enostr -> "ENOSTR"
    Enosys -> "ENOSYS"
    Enotblk -> "ENOTBLK"
    Enotdir -> "ENOTDIR"
    Enotsup -> "ENOTSUP"
    Enxio -> "ENXIO"
    Eopnotsupp -> "EOPNOTSUPP"
    Eoverflow -> "EOVERFLOW"
    Eperm -> "EPERM"
    Epipe -> "EPIPE"
    Erange -> "ERANGE"
    Erofs -> "EROFS"
    Espipe -> "ESPIPE"
    Esrch -> "ESRCH"
    Estale -> "ESTALE"
    Etxtbsy -> "ETXTBSY"
    Exdev -> "EXDEV"
  }
}

fn string_to_io_error(error: String) -> IoError {
  case error {
    "EACCES" -> PosixError(Eacces)
    "EAGAIN" -> PosixError(Eagain)
    "EBADF" -> PosixError(Ebadf)
    "EBADMSG" -> PosixError(Ebadmsg)
    "EBUSY" -> PosixError(Ebusy)
    "EDEADLK" -> PosixError(Edeadlk)
    "EDEADLOCK" -> PosixError(Edeadlock)
    "EDQUOT" -> PosixError(Edquot)
    "EEXIST" -> PosixError(Eexist)
    "EFAULT" -> PosixError(Efault)
    "EFBIG" -> PosixError(Efbig)
    "EFTYPE" -> PosixError(Eftype)
    "EINTR" -> PosixError(Eintr)
    "EINVAL" -> PosixError(Einval)
    "EIO" -> PosixError(Eio)
    "EISDIR" -> PosixError(Eisdir)
    "ELOOP" -> PosixError(Eloop)
    "EMFILE" -> PosixError(Emfile)
    "EMLINK" -> PosixError(Emlink)
    "EMULTIHOP" -> PosixError(Emultihop)
    "ENAMETOOLONG" -> PosixError(Enametoolong)
    "ENFILE" -> PosixError(Enfile)
    "ENOBUFS" -> PosixError(Enobufs)
    "ENODEV" -> PosixError(Enodev)
    "ENOLCK" -> PosixError(Enolck)
    "ENOLINK" -> PosixError(Enolink)
    "ENOENT" -> PosixError(Enoent)
    "ENOMEM" -> PosixError(Enomem)
    "ENOSPC" -> PosixError(Enospc)
    "ENOSR" -> PosixError(Enosr)
    "ENOSTR" -> PosixError(Enostr)
    "ENOSYS" -> PosixError(Enosys)
    "ENOTBLK" -> PosixError(Enotblk)
    "ENOTDIR" -> PosixError(Enotdir)
    "ENOTSUP" -> PosixError(Enotsup)
    "ENXIO" -> PosixError(Enxio)
    "EOPNOTSUPP" -> PosixError(Eopnotsupp)
    "EOVERFLOW" -> PosixError(Eoverflow)
    "EPERM" -> PosixError(Eperm)
    "EPIPE" -> PosixError(Epipe)
    "ERANGE" -> PosixError(Erange)
    "EROFS" -> PosixError(Erofs)
    "ESPIPE" -> PosixError(Espipe)
    "ESRCH" -> PosixError(Esrch)
    "ESTALE" -> PosixError(Estale)
    "ETXTBSY" -> PosixError(Etxtbsy)
    "EXDEV" -> PosixError(Exdev)
    "EOF" -> Eof
    "UNSUPPORTED" -> Unsupported
    other -> Unknown(other)
  }
}

fn map_to_io_error(
  result: Future(Result(value, String)),
) -> Future(Result(value, IoError)) {
  use result <- future.await(result)
  let new_result = case result {
    Ok(data) -> Ok(data)
    Error(error) -> Error(string_to_io_error(error))
  }
  future.resolve(new_result)
}

pub type IoError {
  PosixError(error: PosixError)
  Eof
  Unsupported
  Unknown(msg: String)
}

/// Exported from `gleam/io` for convenience.
/// 
/// Writes a string to standard output (stdout).
///
/// If you want your output to be printed on its own line see `println`.
///
/// ## Example
///
/// ```gleam
/// io.print("Hi mum")
/// // -> Nil
/// // Hi mum
/// ```
///
pub const print: fn(String) -> Nil = io.print

/// Exported from `gleam/io` for convenience.
/// 
/// Writes a string to standard error (stderr).
///
/// If you want your output to be printed on its own line see `println_error`.
///
/// ## Example
///
/// ```gleam
/// io.print_error("Hi pop")
/// // -> Nil
/// // Hi pop
/// ```
///
pub const print_error: fn(String) -> Nil = io.print_error

/// Exported from `gleam/io` for convenience.
/// 
/// Writes a string to standard output (stdout), appending a newline to the end.
///
/// ## Example
///
/// ```gleam
/// io.println("Hi mum")
/// // -> Nil
/// // Hi mum
/// ```
///
pub const println: fn(String) -> Nil = io.println

/// Exported from `gleam/io` for convenience.
/// 
/// Writes a string to standard error (stderr), appending a newline to the end.
///
/// ## Example
///
/// ```gleam
/// io.println_error("Hi pop")
/// // -> Nil
/// // Hi pop
/// ```
///
pub const println_error: fn(String) -> Nil = io.println_error

/// The standard input device.
@external(javascript, "./io_ffi.mjs", "stdin")
pub fn stdin() -> Scanner

/// The standard output device.
@external(javascript, "./io_ffi.mjs", "stdout")
pub fn stdout() -> Appender

/// The standard error device.
@external(javascript, "./io_ffi.mjs", "stderr")
pub fn stderr() -> Appender

/// Represents an I/O device that can be read from.
pub type Reader

/// Represents an I/O device that can be scanned.
pub type Scanner

/// Represents an I/O device that can be written to.
pub type Writer

/// Represents an I/O device that can be appended to.
pub type Appender

/// Reads data from the given device.
pub fn read(
  from device: Reader,
  at position: IoPosition,
  for length: Option(Int),
) -> Future(Result(BitArray, IoError)) {
  case position {
    Absolute(pos) ->
      read_absolute(from: device, at: pos, for: length) |> map_to_io_error
    End -> read_end(from: device, for: length) |> map_to_io_error
    Start -> read_start(from: device, for: length) |> map_to_io_error
  }
}

@external(javascript, "./io_ffi.mjs", "readAbsolute")
fn read_absolute(
  from device: Reader,
  at position: Int,
  for length: Option(Int),
) -> Future(Result(BitArray, String))

@external(javascript, "./io_ffi.mjs", "readEnd")
fn read_end(
  from device: Reader,
  for length: Option(Int),
) -> Future(Result(BitArray, String))

@external(javascript, "./io_ffi.mjs", "readStart")
fn read_start(
  from device: Reader,
  for length: Option(Int),
) -> Future(Result(BitArray, String))

/// Reads all data from the given device.
@external(javascript, "./io_ffi.mjs", "readAll")
pub fn read_all(from device: Reader) -> Future(Result(BitArray, String))

pub type IoPosition {
  Absolute(Int)
  End
  Start
}

/// Writes data to the given device.
pub fn write(
  to device: Writer,
  with data: BitArray,
  at position: IoPosition,
) -> Future(Result(Nil, IoError)) {
  case position {
    Absolute(pos) ->
      write_absolute(to: device, with: data, at: pos) |> map_to_io_error
    End -> write_end(to: device, with: data) |> map_to_io_error
    Start -> write_start(to: device, with: data) |> map_to_io_error
  }
}

@external(javascript, "./io_ffi.mjs", "writeAbsolute")
fn write_absolute(
  to device: Writer,
  with data: BitArray,
  at position: Int,
) -> Future(Result(Nil, String))

@external(javascript, "./io_ffi.mjs", "writeEnd")
fn write_end(
  to device: Writer,
  with data: BitArray,
) -> Future(Result(Nil, String))

@external(javascript, "./io_ffi.mjs", "writeStart")
fn write_start(
  to device: Writer,
  with data: BitArray,
) -> Future(Result(Nil, String))

pub fn append(
  to device: Appender,
  with data: BitArray,
) -> Future(Result(Nil, IoError)) {
  do_append(to: device, with: data) |> map_to_io_error
}

@external(javascript, "./io_ffi.mjs", "append")
fn do_append(
  to device: Appender,
  with data: BitArray,
) -> Future(Result(Nil, String))

@external(javascript, "./io_ffi.mjs", "stream")
pub fn stream(
  from device: Reader,
  size max_chunk_size: Option(Int),
) -> Stream(Result(BitArray, IoError))
