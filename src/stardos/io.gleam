import gleam/io
import stardos/internal/io_error

pub type IoError =
  io_error.IoError

pub const println = io.println

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
