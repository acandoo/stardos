# Stardos IO Device API — detailed design

This document specifies `stardos/io/device`, the generic I/O device abstraction, and `stardos/io/stdio`, the standard stream accessors.

**Error handling:** All fallible operations return `Result(T, IoError)`. See `DESIGN_SUMMARY.md` for the unified error type definition.

## Design principle

`stardos/io/device` is the foundation for composable I/O. It defines:

- A minimal type (`IoDevice`) covering files, sockets, pipes, TTYs.
- Core operations (`read`, `write`, `close`) shared by all device types.
- Optional operations (`seek`, detection predicates) for advanced use.

All high-level modules (process, files, sockets) expose their I/O streams as `IoDevice` instances, enabling generic piping and transformation code.

## Device Type and Interface

```gleam
pub type IoDevice {
  FileDevice(FileHandle)
  ProcessDevice(ProcessHandle, stream_type: StreamType)
  SocketDevice(SocketHandle)
  TtyDevice(TtyHandle)
  StdioDevice(std_stream: StdStream)
}
/// Opaque handle to an I/O device. Variants depend on source.

pub type StdStream {
  Stdin
  Stdout
  Stderr
}
/// Standard stream selector (used by process and stdio modules).
```

## Core Operations

### `read` — read data from device

```gleam
pub fn read(device: IoDevice, n_bytes: Int) -> Result(BitArray, IoError)
```

Read up to `n_bytes` from the device. Returns fewer bytes if EOF is reached.

**Notes:**

- May block until data is available.
- Returns empty BitArray at EOF.
- Returns `Error(io.NotReadable)` for write-only devices.

### `read_all` — read entire device

```gleam
pub fn read_all(device: IoDevice) -> Result(BitArray, IoError)
```

Read all remaining data from the device until EOF. Useful for small files or process output.

**Caution:** Can consume large amounts of memory for large streams.

### `write` — write data to device

```gleam
pub fn write(device: IoDevice, data: BitArray) -> Result(Int, IoError)
```

Write data to the device. Returns the number of bytes written (may be less than requested for non-blocking I/O).

**Notes:**

- May block until space is available.
- Returns `Error(io.NotWritable)` for read-only devices.

### `write_all` — write all data

```gleam
pub fn write_all(device: IoDevice, data: BitArray) -> Result(Nil, IoError)
```

Write all data to the device, blocking until complete. Raises error if write fails partway through.

### `close` — close device

```gleam
pub fn close(device: IoDevice) -> Result(Nil, IoError)
```

Close the device and free resources. Subsequent operations will fail.

### `is_readable` — check if device is readable

```gleam
pub fn is_readable(device: IoDevice) -> Bool
```

Return `True` if the device supports read operations.

### `is_writable` — check if device is writable

```gleam
pub fn is_writable(device: IoDevice) -> Bool
```

Return `True` if the device supports write operations.

### `copy` — copy from one device to another

```gleam
pub fn copy(from: IoDevice, to: IoDevice) -> Result(Int, IoError)
```

Copy all data from `from` to `to`, returning total bytes copied. Equivalent to streaming the source until EOF.

**Example:**

```gleam
import stardos/io/device

case device.copy(file_device, stdout_device) {
  Ok(bytes) -> io.println("Copied " <> int.to_string(bytes) <> " bytes")
  Error(e) -> io.println("Copy failed")
}
```

### `seek` — seek to position (optional)

```gleam
pub fn seek(device: IoDevice, offset: Int, whence: SeekWhence) -> Result(Int, IoError)
```

Seek to a position in the device (files only). Returns new position.

```gleam
pub type SeekWhence {
  SeekStart   // offset from start
  SeekCurrent // offset from current position
  SeekEnd     // offset from end
}
```

**Notes:**

- Only supported by file devices.
- Returns `Error(io.Unsupported)` for pipes, sockets, or TTYs.

## Stdio Module (`stardos/io/stdio`)

Standard stream accessors and convenience functions.

### `stdin` — standard input device

```gleam
pub fn stdin() -> Result(IoDevice, IoError)
```

Get a readable device for standard input. Returns `Error(io.Unsupported)` in environments without stdin.

### `stdout` — standard output device

```gleam
pub fn stdout() -> Result(IoDevice, IoError)
```

Get a writable device for standard output.

### `stderr` — standard error device

```gleam
pub fn stderr() -> Result(IoDevice, IoError)
```

Get a writable device for standard error.

### `print` — write to stdout

```gleam
pub fn print(text: String) -> Result(Nil, IoError)
```

Write text to stdout without a trailing newline.

### `println` — write line to stdout

```gleam
pub fn println(text: String) -> Result(Nil, IoError)
```

Write text to stdout with a trailing newline.

### `eprint` — write to stderr

```gleam
pub fn eprint(text: String) -> Result(Nil, IoError)
```

Write text to stderr without a trailing newline.

### `eprintln` — write line to stderr

```gleam
pub fn eprintln(text: String) -> Result(Nil, IoError)
```

Write text to stderr with a trailing newline.

### `read_line` — read line from stdin

```gleam
pub fn read_line() -> Result(String, IoError)
```

Read a single line from stdin (up to newline). Newline is stripped.

**Example:**

```gleam
import stardos/io/stdio

case stdio.read_line() {
  Ok(input) -> io.println("You entered: " <> input)
  Error(e) -> io.println("Failed to read input")
}
```

### `isatty` — check if stdout is a TTY

```gleam
pub fn isatty(stream: StdStream) -> Bool
```

Return `True` if the given standard stream is connected to a terminal (as opposed to a file or pipe).

**Use case:** Conditional color output based on TTY detection.

```gleam
case stdio.isatty(stdio.Stdout) {
  True -> print_colored_output()
  False -> print_plain_output()
}
```

## Buffered I/O Helpers

### `buffered_reader` — create buffered reader

```gleam
pub fn buffered_reader(device: IoDevice, buffer_size: Int) -> BufferedReader
```

Wrap a device in a buffered reader for efficient reading.

### `buffered_writer` — create buffered writer

```gleam
pub fn buffered_writer(device: IoDevice, buffer_size: Int) -> BufferedWriter
```

Wrap a device in a buffered writer for efficient writing.

### `lines` — iterate lines from device

```gleam
pub fn lines(device: IoDevice) -> Result(List(String), IoError)
```

Read all lines from a device as a list. Strips newlines.

**Example:**

```gleam
case device.lines(file_dev) {
  Ok(lines) -> list.each(lines, io.println)
  Error(e) -> io.println("Failed to read lines")
}
```

## Cross-target notes

| Function       | BEAM | Node | Browser      |
| -------------- | ---- | ---- | ------------ |
| `read`         | ✓    | ✓    | ⚠️           |
| `write`        | ✓    | ✓    | ⚠️           |
| `close`        | ✓    | ✓    | ⚠️           |
| `seek` (files) | ✓    | ✓    | ⚠️           |
| `stdin`        | ✓    | ✓    | ❌           |
| `stdout`       | ✓    | ✓    | ⚠️ (console) |
| `stderr`       | ✓    | ✓    | ⚠️ (console) |
| `isatty`       | ✓    | ✓    | ⚠️           |

**Notes:**

- BEAM/Node: all operations available.
- Browser: limited I/O; stdout/stderr may map to `console.log`. stdin unavailable. File operations limited by sandbox.

## Examples

### Copy file to stdout

```gleam
import stardos/io/device
import stardos/io/stdio

case device.copy(input_file, stdio.stdout()) {
  Ok(_) -> Nil
  Error(e) -> io.println("Copy failed")
}
```

### Read all input

```gleam
import stardos/io/stdio

case stdio.read_line() {
  Ok(line) -> io.println("Read: " <> line)
  Error(e) -> io.println("Error")
}
```

### Buffered line reading

```gleam
import stardos/io/device
import stardos/io/stdio

let file = // open file
case device.lines(file) {
  Ok(lines) -> list.each(lines, process_line)
  Error(_) -> Nil
}
```

## Summary

`stardos/io/device` provides a minimal, composable abstraction for all I/O endpoints. `stardos/io/stdio` builds convenience helpers on top. Together they enable generic, ergonomic streaming code.
