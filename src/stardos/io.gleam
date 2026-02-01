import gleam/io

pub type PosixError {
  Eacces
  Eagain
  Ebadf
  Ebadmsg
  Ebusy
  Edeadlk
  Edeadlock
  Edquot
  Eexist
  Efault
  Efbig
  Eftype
  Eintr
  Einval
  Eio
  Eisdir
  Eloop
  Emfile
  Emlink
  Emultihop
  Enametoolong
  Enfile
  Enobufs
  Enodev
  Enolck
  Enolink
  Enoent
  Enomem
  Enospc
  Enosr
  Enostr
  Enosys
  Enotblk
  Enotdir
  Enotsup
  Enxio
  Eopnotsupp
  Eoverflow
  Eperm
  Epipe
  Erange
  Erofs
  Espipe
  Esrch
  Estale
  Etxtbsy
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

/// The standard input device.
@external(javascript, "./io_ffi.mjs", "stdin")
pub fn stdin() -> IoDevice

/// The standard output device.
@external(javascript, "./io_ffi.mjs", "stdout")
pub fn stdout() -> IoDevice

/// The standard error device.
@external(javascript, "./io_ffi.mjs", "stderr")
pub fn stderr() -> IoDevice

/// The permissions 
pub type IoPermissions {
  ReadOnly
  WriteOnly(mode: WriteMode)
  ReadWrite(mode: WriteMode)
}

/// The mode which write operations are performed.
/// In `Absolute` mode, a write operation can written at any 
/// In `Append` mode, the 
pub type WriteMode {
  Absolute
  Append
}

/// Represents an I/O device, such as a file or network socket.
pub type IoDevice
