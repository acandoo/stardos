import stardos/io.{type Appender, type Scanner}

pub type TtyInput

pub type TtyOutput

pub type TtyError {
  NotATty
  UnsupportedByRuntime
  IoError(io_error: io.IoError)
}

@external(javascript, "./tty_ffi.mjs", "todo")
pub fn stdin() -> TtyInput

@external(javascript, "./tty_ffi.mjs", "todo")
pub fn stdout() -> TtyOutput

@external(javascript, "./tty_ffi.mjs", "todo")
pub fn stderr() -> TtyOutput

@external(javascript, "./tty_ffi.mjs", "todo")
pub fn input_from(scanner: Scanner) -> Result(TtyInput, TtyError)

@external(javascript, "./tty_ffi.mjs", "todo")
pub fn writer_from(appender: Appender) -> Result(TtyOutput, TtyError)

@external(javascript, "./tty_ffi.mjs", "todo")
pub fn is_raw(reader: TtyInput) -> Bool

@external(javascript, "./tty_ffi.mjs", "todo")
pub fn set_raw(reader: TtyInput) -> Nil
