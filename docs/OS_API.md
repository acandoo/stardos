# Stardos OS API — detailed design

This document specifies `stardos/os`, the system information and host metadata module.

**Error handling:** Fallible operations return `Result(T, IoError)`. See `DESIGN_SUMMARY.md` for error type definition.

## Core principle

`stardos/os` provides read-only host information: platform, architecture, hostname, CPU count, uptime. These are system-wide facts, not process-specific.

## Types

```gleam
pub type Platform {
  Linux
  MacOS
  Windows
  FreeBsd
  Unknown(String)
}
/// Platform identification.

pub type Arch {
  X86
  X86_64
  Arm
  Arm64
  Mips
  Unknown(String)
}
/// CPU architecture.
```

## API

### `platform` — get OS platform

```gleam
pub fn platform() -> Platform
```

Return the platform running this process (Linux, macOS, Windows, etc.).

**Example:**

```gleam
case os.platform() {
  Linux -> io.println("Running on Linux")
  MacOS -> io.println("Running on macOS")
  Windows -> io.println("Running on Windows")
  Unknown(name) -> io.println("Unknown OS: " <> name)
}
```

### `arch` — get CPU architecture

```gleam
pub fn arch() -> Arch
```

Return the CPU architecture (x86_64, arm64, etc.).

### `hostname` — get machine hostname

```gleam
pub fn hostname() -> Result(String, IoError)
```

Get the hostname of the machine. May fail if unset or unresolvable.

**Example:**

```gleam
case os.hostname() {
  Ok(name) -> io.println("Hostname: " <> name)
  Error(_) -> io.println("Could not determine hostname")
}
```

### `num_cpus` — get CPU count

```gleam
pub fn num_cpus() -> Int
```

Return the number of logical CPUs. Useful for determining parallelism bounds.

**Example:**

```gleam
let cpu_count = os.num_cpus()
let worker_threads = max(1, cpu_count - 1)
```

### `num_cpus_available` — get available CPUs

```gleam
pub fn num_cpus_available() -> Option(Int)
```

Return the number of CPUs available to this process (respecting cgroup limits, etc.). Returns `None` if unavailable.

### `uptime` — get system uptime

```gleam
pub fn uptime() -> Result(Float, IoError)
```

Return the system uptime in seconds (time since last boot). May be unavailable on some platforms.

### `load_average` — get load average

```gleam
pub fn load_average() -> Result(#(Float, Float, Float), IoError)
```

Get the 1-minute, 5-minute, and 15-minute load averages. Returns `Error` if unavailable (e.g., Windows).

**Example:**

```gleam
case os.load_average() {
  Ok(#(one, five, fifteen)) -> {
    io.println("Load: " <> float.to_string(one))
  }
  Error(_) -> io.println("Load average unavailable")
}
```

### `kernel_version` — get kernel version string

```gleam
pub fn kernel_version() -> Option(String)
```

Return a string describing the kernel version (e.g., "5.10.0-8-generic"). Returns `None` if unavailable.

### `os_release_info` — get distro/release info

```gleam
pub fn os_release_info() -> Result(OsReleaseInfo, IoError)
```

Return parsed `/etc/os-release` info (Linux). Returns `Error` on non-Linux platforms or if file missing.

```gleam
pub type OsReleaseInfo {
  OsReleaseInfo(
    name: String,
    version: Option(String),
    pretty_name: String,
    id: Option(String),
  )
}
```

**Notes:** Limited to Linux (reads `/etc/os-release`). On Windows/macOS, returns `Error(io.Unsupported)`.

## Cross-target notes

| Function          | BEAM | Node | Browser |
| ----------------- | ---- | ---- | ------- |
| `platform`        | ✓    | ✓    | ✓       |
| `arch`            | ✓    | ✓    | ✓       |
| `hostname`        | ✓    | ✓    | ⚠️      |
| `num_cpus`        | ✓    | ✓    | ✓       |
| `uptime`          | ✓    | ✓    | ⚠️      |
| `load_average`    | ✓    | ⚠️   | ⚠️      |
| `kernel_version`  | ✓    | ✓    | ⚠️      |
| `os_release_info` | ✓    | ✓    | ❌      |

**Notes:**

- Browser: limited to platform/arch (exposed via user agent). Uptime, load, hostname all unavailable or meaningless.
- `load_average` is Unix-only (Windows returns `Error`).
- `os_release_info` is Linux-only.

## Examples

### Platform-specific branching

```gleam
import stardos/os

pub fn setup() {
  case os.platform() {
    Linux -> setup_linux()
    Windows -> setup_windows()
    MacOs -> setup_macos()
    Unknown(_) -> io.println("Unknown platform")
  }
}
```

### CPU-based scaling

```gleam
import stardos/os

pub fn configure_workers() {
  let cpus = os.num_cpus()
  let workers = case cpus {
    1 -> 1
    2 | 3 -> cpus
    _ -> cpus - 1 // reserve one CPU
  }
  io.println("Spawning " <> int.to_string(workers) <> " workers")
}
```

### System health check

```gleam
import stardos/os

pub fn check_load() {
  case os.load_average() {
    Ok(#(one_min, _, _)) if one_min > 8.0 -> {
      io.println("WARNING: High load average")
    }
    _ -> Nil
  }
}
```

## Summary

`stardos/os` provides read-only system information useful for platform detection, capacity planning, and diagnostics. It complements `stardos/env` (process-level) and `stardos/process` (process control).
