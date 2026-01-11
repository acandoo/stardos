# Stardos Terminal API — detailed design

This document specifies `stardos/io/term`, the terminal/TTY detection and control module.

**Error handling:** Operations return `Result(T, Nil)` for failures. See `DESIGN_SUMMARY.md` for error handling patterns.

## Core principle

`stardos/term` provides utilities for querying and controlling terminal I/O properties: TTY detection, dimensions, and control (raw mode, cursor).

## Types

```gleam
pub type TerminalSize {
  TerminalSize(columns: Int, rows: Int)
}
/// Terminal dimensions.
```

## API

### `isatty` — check if stream is TTY

```gleam
pub fn isatty(fd: Int) -> Bool
```

Return `True` if the file descriptor is connected to a terminal (TTY), `False` otherwise.

**Common FD values:**

- 0 — stdin
- 1 — stdout
- 2 — stderr

**Example:**

```gleam
import stardos/term

case term.isatty(1) {
  True -> io.println("Running interactively")
  False -> io.println("Output is redirected")
}
```

### `size` — get terminal dimensions

```gleam
pub fn size() -> Result(TerminalSize, Nil)
```

Get the current terminal size (columns and rows). Returns `Error(Nil)` if not a TTY or unavailable.

**Example:**

```gleam
case term.size() {
  Ok(size) -> {
    io.println("Terminal: " <> int.to_string(size.columns) <> "x" <> int.to_string(size.rows))
  }
  Error(Nil) -> io.println("Not a TTY or size unavailable")
}
```

### `width` — get terminal width

```gleam
pub fn width() -> Result(Int, Nil)
```

Get the terminal width in columns. Convenience for `size()`.

### `height` — get terminal height

```gleam
pub fn height() -> Result(Int, Nil)
```

Get the terminal height in rows. Convenience for `size()`.

### `enable_raw_mode` — enter raw mode

```gleam
pub fn enable_raw_mode() -> Result(Nil, IoError)
```

Enable raw mode for the terminal (disable buffering, echo, etc.). Useful for interactive applications (text editors, games, etc.).

**Notes:**

- Only applies to stdin/stdout/stderr connections to a TTY.
- Returns `Error(io.Unsupported)` if not a TTY.
- **Caveat:** Must be paired with `disable_raw_mode()` on exit to restore terminal state.

### `disable_raw_mode` — exit raw mode

```gleam
pub fn disable_raw_mode() -> Result(Nil, IoError)
```

Restore terminal to normal (cooked) mode after `enable_raw_mode()`.

### `clear_screen` — clear terminal

```gleam
pub fn clear_screen() -> Result(Nil, IoError)
```

Clear the terminal screen and move cursor to top-left.

**Example:**

```gleam
import stardos/term

term.clear_screen()
```

### `set_cursor_position` — move cursor

```gleam
pub fn set_cursor_position(row: Int, col: Int) -> Result(Nil, IoError)
```

Move the cursor to the given (row, col) position (0-indexed or 1-indexed depending on convention; document choice).

### `hide_cursor` — hide cursor

```gleam
pub fn hide_cursor() -> Result(Nil, IoError)
```

Hide the terminal cursor (useful for animations/TUIs).

### `show_cursor` — show cursor

```gleam
pub fn show_cursor() -> Result(Nil, IoError)
```

Show the terminal cursor.

## Convenience layer (future)

While color output is outside the scope of `stardos/term`, a higher-level module `stardos/term/color` could be added later for ANSI color support.

## Cross-target notes

| Function              | BEAM | Node | Browser |
| --------------------- | ---- | ---- | ------- |
| `isatty`              | ✓    | ✓    | ⚠️      |
| `size`                | ✓    | ✓    | ⚠️      |
| `enable_raw_mode`     | ✓    | ⚠️   | ❌      |
| `disable_raw_mode`    | ✓    | ⚠️   | ❌      |
| `clear_screen`        | ✓    | ✓    | ⚠️      |
| `set_cursor_position` | ✓    | ✓    | ⚠️      |

**Notes:**

- BEAM: full support for raw mode and cursor control.
- Node: `enable_raw_mode` may work but is limited; depends on underlying platform and TTY availability.
- Browser: no TTY control available; most functions return `Error(io.Unsupported)`.

## Examples

### Conditional color output

```gleam
import stardos/term

pub fn print_status(message: String) {
  case term.isatty(1) {
    True -> io.println("\u{001b}[32m✓ " <> message <> "\u{001b}[0m") // green
    False -> io.println("✓ " <> message)
  }
}
```

### Responsive layout

```gleam
import stardos/term

pub fn print_padded(text: String) {
  case term.width() {
    Some(width) -> {
      let padding = max(0, width - string.length(text))
      io.println(text <> string.repeat(" ", padding))
    }
    None -> io.println(text)
  }
}
```

### Raw mode for interactive input

```gleam
import stardos/term

pub fn interactive_prompt() {
  // Enable raw mode for character-by-character input
  let _ = term.enable_raw_mode()

  // Read characters directly (not implemented here, but illustrative)
  // let ch = read_char()

  // Restore normal mode
  let _ = term.disable_raw_mode()
  Nil
}
```

## Summary

`stardos/term` provides TTY detection and basic terminal control. It's the foundation for interactive command-line and terminal UI applications. Use with caution; raw mode and cursor control are platform-specific.
