# Stardos Env API — detailed design

This document specifies `stardos/env`, the process-level environment and working directory module.

**Error handling:** Fallible operations return `Result(T, IoError)`. See `DESIGN_SUMMARY.md` for error type definition.

## Core principle

`stardos/env` provides process-scoped configuration: environment variables, working directory, and per-process helpers. These affect only the current process and are not system-wide.

## Types

All env operations use `Result(T, IoError)` for consistency with other modules. See `stardos/io` for the unified error type.

## API

### `get` — retrieve an environment variable

```gleam
pub fn get(key: String) -> Option(String)
```

Look up an environment variable by key. Returns `None` if not set.

**Example:**

```gleam
case env.get("PORT") {
  Some(port) -> port
  None -> "8080"
}
```

### `get_or` — with default fallback

```gleam
pub fn get_or(key: String, default: String) -> String
```

Look up an environment variable, returning a default if not found. Convenience wrapper.

**Example:**

```gleam
let port = env.get_or("PORT", "8080")
```

### `set` — set an environment variable

```gleam
pub fn set(key: String, value: String) -> Result(Nil, IoError)
```

Set an environment variable for the current process and any child processes spawned afterward.

**Notes:**

- Affects only the current process and its descendants.
- May fail if key or value is invalid on the platform.
- On BEAM, may have limited effect depending on Erlang version.

### `remove` — unset an environment variable

```gleam
pub fn remove(key: String) -> Result(Nil, IoError)
```

Remove an environment variable from the current process.

### `vars` — get all environment variables

```gleam
pub fn vars() -> List(#(String, String))
```

Return all environment variables as a list of (key, value) pairs.

**Performance note:** This is a relatively heavy operation; avoid calling repeatedly in tight loops.

### `cwd` — get current working directory

```gleam
pub fn cwd() -> Result(String, IoError)
```

Get the absolute path of the current working directory.

**Example:**

```gleam
case env.cwd() {
  Ok(dir) -> io.println("CWD: " <> dir)
  Error(_) -> io.println("Could not determine CWD")
}
```

### `chdir` — change current working directory

```gleam
pub fn chdir(path: String) -> Result(Nil, IoError)
```

Change the working directory of the current process. Relative paths are resolved relative to the current directory.

**Notes:**

- Affects only the current process; does not change parent or sibling processes' directories.
- Commonly used before running subprocesses that depend on relative paths.

**Example:**

```gleam
case env.chdir("/tmp") {
  Ok(Nil) -> io.println("Changed to /tmp")
  Error(e) -> io.println("Failed to change directory")
}
```

### `home_dir` — get user's home directory

```gleam
pub fn home_dir() -> Result(String, Nil)
```

Return the home directory of the current user (e.g., `/home/username` on Linux, `C:\Users\username` on Windows). Returns `Error(Nil)` if not determinable.

**Implementation notes:**

- On Unix: read `$HOME` env var or `passwd` database.
- On Windows: read `%USERPROFILE%` or registry.

### `temp_dir` — get system temporary directory

```gleam
pub fn temp_dir() -> String
```

Return the system temporary directory (e.g., `/tmp` on Linux, `C:\Temp` on Windows). Always succeeds; returns a platform-appropriate path.

### `umask` — get/set file creation mask

```gleam
pub fn umask(mask: Int) -> Int
```

Set the file creation mask and return the previous mask. This controls the default permissions of newly created files.

**Notes:**

- Parameter is a 3-digit octal mask (e.g., `0o022`).
- On Windows, this function has limited or no effect.
- Rarely used in modern code; documented for completeness.

### `current_user_name` — get current username

```gleam
pub fn current_user_name() -> Option(String)
```

Return the username of the current process owner. Returns `None` if not available.

## Cross-target notes

| Function   | BEAM | Node | Browser      |
| ---------- | ---- | ---- | ------------ |
| `get`      | ✓    | ✓    | ⚠️ (empty)   |
| `set`      | ✓    | ✓    | ❌           |
| `remove`   | ✓    | ✓    | ❌           |
| `vars`     | ✓    | ✓    | ⚠️ (empty)   |
| `cwd`      | ✓    | ✓    | ✓            |
| `chdir`    | ✓    | ✓    | ⚠️ (limited) |
| `home_dir` | ✓    | ✓    | ⚠️           |
| `temp_dir` | ✓    | ✓    | ✓            |
| `umask`    | ✓    | ✓    | ❌           |

**Notes:**

- Browser environments have no persistent environment and no process-level working directory in the traditional sense. `cwd`/`chdir` may work with conceptual file system sandboxes.
- `get`/`vars` return empty on browser (no env vars exposed).

## Examples

### Port configuration pattern

```gleam
import stardos/env

pub fn configure_server() {
  let host = env.get_or("HOST", "localhost")
  let port = env.get_or("PORT", "8080")
  io.println("Server on " <> host <> ":" <> port)
}
```

### Working with temporary files

```gleam
import stardos/env

pub fn create_temp_config() {
  let temp = env.temp_dir()
  let config_path = temp <> "/my_config.txt"
  // write to config_path
  config_path
}
```

### Set custom env for child process

```gleam
import stardos/env
import stardos/process

pub fn run_with_custom_env() {
  env.set("DEBUG", "1")
  // Now spawn a child process; it inherits DEBUG=1
  case process.run("./my_script", []) {
    Ok(output) -> io.println("Done")
    Error(e) -> io.println("Failed")
  }
}
```

## Summary

`stardos/env` provides ergonomic access to the process environment: variables, working directory, and user identity. It's designed for configuration and lightweight environment manipulation, complementing `stardos/process` which runs subprocesses with custom environments.
