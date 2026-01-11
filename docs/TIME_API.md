# Stardos Time API — detailed design

This document specifies `stardos/time`, the system time and clock module.

**Error handling:** Fallible operations return `Result(T, IoError)`. See `DESIGN_SUMMARY.md` for error type definition.

## Core principle

`stardos/time` provides access to wall-clock and monotonic clocks, time formatting/parsing, timezone info, and sleep/delay utilities. The API is inspired by Rust's `std::time` and JS Temporal, emphasizing clarity and composability.

## Types

```gleam
pub type SystemTime {
  SystemTime(seconds: Int, nanos: Int)
}
/// An instant in wall-clock time (seconds + nanoseconds since Unix epoch, Jan 1 1970 UTC).
/// Analogous to Rust's `std::time::SystemTime` and JS Temporal's `Temporal.Instant`.

pub type Instant {
  Instant(nanos: Int)
}
/// A point on a monotonic clock (never goes backwards, unaffected by system clock adjustments).
/// Used for measuring elapsed time reliably.

pub type Duration {
  Duration(secs: Int, nanos: Int)
}
/// A span of time (seconds + nanoseconds). Always non-negative.

pub type TimeZone {
  TimeZone(name: String, offset_seconds: Int)
}
/// Timezone information (name and offset from UTC).
```

## API

### `now` — current system time

```gleam
pub fn now() -> SystemTime
```

Get the current wall-clock time as an instant since Unix epoch (Jan 1, 1970 UTC).

**Example:**

```gleam
let time = time.now()
case time {
  SystemTime(secs, nanos) -> {
    io.println("Current time: " <> int.to_string(secs) <> "." <> int.to_string(nanos))
  }
}
```

### `now_millis` — current time in milliseconds

```gleam
pub fn now_millis() -> Int
```

Get the current time as milliseconds since Unix epoch. Convenience for `now()`.

**Example:**

````gleam

### `parse_time` — parse ISO 8601 time string

```gleam
pub fn parse_time(iso8601: String) -> Result(SystemTime, Nil)
````

Parse an ISO 8601 formatted time string into a `SystemTime`. Returns `Error(Nil)` if parsing fails.

**Example:**

```gleam
case time.parse_time("2024-01-11T15:30:45Z") {
  Ok(t) -> io.println("Parsed time")
  Error(Nil) -> io.println("Invalid format")
}
```

let start = time.now_millis()
// ... do work ...
let elapsed_ms = time.now_millis() - start

````

### `duration_since` — compute duration between two times

```gleam
pub fn duration_since(from: SystemTime, to: SystemTime) -> Result(Duration, Nil)
````

Compute the duration between two system times. Returns `Error(Nil)` if `to` is before `from`.

### `now_seconds` — current time in seconds

```gleam
pub fn now_seconds() -> Float
```

Get the current time as seconds since Unix epoch (with fractional seconds). Convenience for `now()`.

### `time_to_string` — format time

```gleam
pub fn time_to_string(t: SystemTime) -> String
```

Format a system time as an ISO 8601 string (e.g., "2024-01-11T15:30:45Z").

### `monotonic_now` — monotonic clock

```gleam
pub fn monotonic_now() -> Instant
```

Get a reading from a monotonic clock (never goes backwards, unaffected by NTP adjustments). Useful for measuring elapsed time.

**Example:**

```gleam
let start = time.monotonic_now()
// ... do work ...
let end = time.monotonic_now()
let elapsed = time.elapsed(start, end)
io.println("Elapsed: " <> float.to_string(elapsed) <> " seconds")
```

### `elapsed` — compute elapsed time (monotonic)

```gleam
pub fn elapsed(from: Instant, to: Instant) -> Duration
```

Compute the duration between two monotonic instants. Always non-negative.

### `sleep` — sleep for duration

```gleam
pub fn sleep(seconds: Float) -> Nil
```

Sleep (block) for the given number of seconds.

**Notes:**

- Precision depends on OS scheduler; actual sleep may be longer.
- On async-aware runtimes, this may yield to other tasks without blocking the thread.

**Example:**

```gleam
import stardos/time

time.sleep(1.0) // sleep 1 second
io.println("Done sleeping")
```

### `sleep_millis` — sleep for milliseconds

```gleam
pub fn sleep_millis(millis: Int) -> NilNil)
```

Get the current timezone offset from UTC in seconds. Returns `Error(Nil)` if unavailableence for `sleep()`.

### `timezone_offset` — get UTC offset

```gleam
pub fn timezone_offset() -> Result(Int, IoError)
```

Get the current timezone offset from UTC in seconds.

**Example:**

```gleam
case time.timezone_offset() {
  Ok(offset) -> {
    let hours = offset / 3600
    io.println("UTC offset: " <> int.to_string(hours) <> " hours")
  }
  Error(_) -> io.println("Could not determine timezone")
}
```

### `timezone_name` — get timezone name

```gleam
pub fn timezone_name() -> Result(String, Nil)
```

Get the current timezone name (e.g., "UTC", "America/New_York"). Returns `Error(Nil)` if unavailable.

## Cross-target notes

| Function          | BEAM | Node | Browser |
| ----------------- | ---- | ---- | ------- |
| `now`             | ✓    | ✓    | ✓       |
| `now_millis`      | ✓    | ✓    | ✓       |
| `monotonic_now`   | ✓    | ✓    | ✓       |
| `elapsed`         | ✓    | ✓    | ✓       |
| `sleep`           | ✓    | ✓    | ⚠️      |
| `timezone_offset` | ✓    | ✓    | ⚠️      |
| `timezone_name`   | ✓    | ✓    | ⚠️      |

**Notes:**

- BEAM/Node: all functions available.
- Browser: `sleep` may not block; `timezone` info limited by sandboxing.

## Examples

### Measure operation time

```gleam
import stardos/time

let start = time.monotonic_now()
perform_task()
let end = time.monotonic_now()
let elapsed = time.elapsed(start, end)
let secs = time.duration_to_seconds(elapsed)
io.println("Task took " <> float.to_string(secs) <> " seconds")
```

### Rate limiting with sleep

```gleam
import stardos/time

pub fn poll_with_backoff(attempts: Int) {
  case attempts {
    0 -> io.println("Failed after retries")
    n -> {
      case try_operation() {
        Ok(result) -> process(result)
        Error(_) -> {
          io.println("Retry " <> int.to_string(attempts) <> "...")
          time.sleep(0.5)
          poll_with_backoff(n - 1)
        }
      }
    }
  }
}
```

### Log with timestamp

```gleam
import stardos/time

pub fn log(message: String) {
  let ts = time.now() |> time.time_to_string()
  io.println("[" <> ts <> "] " <> message)
}
```

## Summary

`stardos/time` provides ergonomic access to system time and clocks, useful for timestamping, measuring elapsed time, and implementing delays. Monotonic clocks are recommended for measuring elapsed time; wall-clock time is for logging and timestamps.
