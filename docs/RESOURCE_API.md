# Stardos Resource API — detailed design

This document specifies `stardos/resource`, the process resource usage module.

**Error handling:** Operations return `Result(T, IoError)` or `Option(T)`. See `DESIGN_SUMMARY.md` for error type definition.

## Core principle

`stardos/resource` provides inspection of process resource consumption (CPU, memory, file descriptors, etc.).

## Types

```gleam
pub type ResourceUsage {
  ResourceUsage(
    cpu_time_user: Float,    // CPU time in user mode (seconds)
    cpu_time_system: Float,  // CPU time in system mode (seconds)
    memory_rss: Int,         // Resident set size (bytes)
    memory_vms: Int,         // Virtual memory size (bytes)
    num_threads: Int,        // Number of threads
    num_fds: Option(Int),    // Number of open file descriptors (None if unavailable)
  )
}
/// Resource usage statistics for the current process.

pub type Limit {
  Limit(
    soft: Int,    // Soft limit
    hard: Int,    // Hard limit (can increase soft up to hard)
  )
}
/// A resource limit (soft and hard).
```

## API

### `current_usage` — get current resource usage

```gleam
pub fn current_usage() -> Result(ResourceUsage, IoError)
```

Get current resource usage for the process.

**Example:**

```gleam
import stardos/resource

case resource.current_usage() {
  Ok(usage) -> {
    let mb = usage.memory_rss / 1_000_000
    io.println("Memory: " <> int.to_string(mb) <> " MB")
  }
  Error(_) -> io.println("Could not get resource usage")
}
```

### `limit` — get resource limit

```gleam
pub fn limit(kind: LimitKind) -> Result(Limit, IoError)
```

Get the current resource limit for a given resource.

```gleam
pub type LimitKind {
  LimitCpu      // CPU time
  LimitMemory   // Virtual memory
  LimitData     // Data segment size
  LimitStack    // Stack size
  LimitFds      // Open file descriptors
  LimitNofile   // Max open files
}
```

**Example:**

```gleam
case resource.limit(resource.LimitFds) {
  Ok(limit) -> {
    io.println("FD soft limit: " <> int.to_string(limit.soft))
    io.println("FD hard limit: " <> int.to_string(limit.hard))
  }
  Error(_) -> io.println("Could not get limit")
}
```

### `set_limit` — set resource limit

```gleam
pub fn set_limit(kind: LimitKind, soft: Int, hard: Int) -> Result(Nil, IoError)
```

Set a resource limit. The soft limit can be increased up to the hard limit.

**Notes:**

- Requires appropriate privileges (usually root for hard limits).
- Returns `Error(io.PermissionDenied)` if insufficient permissions.
- Behavior depends on OS; some limits cannot be changed.

### `cpu_time` — get CPU time

```gleam
pub fn cpu_time() -> Result(#(Float, Float), IoError)
```

Get CPU time used by current process as (user_time, system_time) in seconds.

### `memory_bytes` — get memory usage

```gleam
pub fn memory_bytes() -> Result(#(Int, Int), IoError)
```

Get memory usage as (rss, vms) in bytes.

### `num_open_files` — count open file descriptors

```gleam
pub fn num_open_files() -> Result(Int, Nil)
```

Get the number of open file descriptors for the current process. Returns `Error(Nil)` if unavailable.

## Cross-target notes

| Function        | BEAM | Node | Browser |
| --------------- | ---- | ---- | ------- |
| `current_usage` | ✓    | ✓    | ⚠️      |
| `limit`         | ✓    | ✓    | ❌      |
| `set_limit`     | ✓    | ✓    | ❌      |
| `cpu_time`      | ✓    | ✓    | ⚠️      |
| `memory_bytes`  | ✓    | ✓    | ✓       |

**Notes:**

- BEAM/Node: most functions available.
- Browser: limited to memory; CPU time and limits unavailable.
- Precision and exact definitions vary by OS (e.g., RSS on Linux vs macOS).

## Examples

### Monitor memory usage

```gleam
import stardos/resource

pub fn check_memory_threshold(threshold_mb: Int) {
  case resource.current_usage() {
    Ok(usage) -> {
      let mb = usage.memory_rss / 1_000_000
      case mb > threshold_mb {
        True -> io.println("WARNING: High memory usage: " <> int.to_string(mb) <> " MB")
        False -> Nil
      }
    }
    Error(_) -> Nil
  }
}
```

### Log resource snapshot

```gleam
import stardos/resource

pub fn log_snapshot() {
  case resource.current_usage() {
    Ok(usage) -> {
      io.println("CPU: " <> float.to_string(usage.cpu_time_user) <> "s user, " <> float.to_string(usage.cpu_time_system) <> "s system")
      let mb = usage.memory_rss / 1_000_000
      io.println("Memory: " <> int.to_string(mb) <> " MB")
    }
    Error(_) -> Nil
  }
}
```

### Check file descriptor limit

```gleam
import stardos/resource

pub fn check_fd_availability() {
  case resource.num_open_files() {
    Some(open) -> {
      case resource.limit(resource.LimitFds) {
        Ok(limit) -> {
          let percentage = (open * 100) / limit.soft
          io.println("File descriptors: " <> int.to_string(open) <> "/" <> int.to_string(limit.soft) <> " (" <> int.to_string(percentage) <> "%)")
        }
        Error(_) -> io.println("Open files: " <> int.to_string(open))
      }
    }
    None -> io.println("Could not determine open file count")
  }
}
```

## Summary

`stardos/resource` provides introspection of process resource usage and limits. Useful for monitoring, diagnostics, and tuning. Resource usage is a snapshot; values change constantly.
