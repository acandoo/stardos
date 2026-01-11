# Stardos User API — detailed design

This document specifies `stardos/user`, the user and group information module.

**Error handling:** Operations return `Result(T, Nil)` for queries that might fail. See `DESIGN_SUMMARY.md` for error handling patterns.

## Core principle

`stardos/user` provides read-only access to user and group information from the system.

## Types

```gleam
pub type UserInfo {
  UserInfo(
    name: String,
    uid: Option(Int),
    gid: Option(Int),
    home: Option(String),
    shell: Option(String),
  )
}
/// Information about a user account.

pub type GroupInfo {
  GroupInfo(
    name: String,
    gid: Int,
    members: List(String),
  )
}
/// Information about a group.
```

## API

### `current_user` — get current process user

```gleam
pub fn current_user() -> Result(UserInfo, Nil)
```

Get the user account information for the current process. Returns `Error(Nil)` if unavailable.

**Notes:**

- On Unix: reads from `/etc/passwd` or system calls like `getpwuid()`.
- On Windows: queries the security context of the current process.
- On limited runtimes (e.g., Node sandboxed), may return `None`.

**Example:**

```gleam
import stardos/user

case user.current_user() {
  Ok(info) -> io.println("Running as: " <> info.name)
  Error(Nil) -> io.println("Could not determine current user")
}
```

### `current_uid` — get user ID

```gleam
pub fn current_uid() -> Result(Int, Nil)
```

Get the numeric user ID (UID) of the current process. Returns `Error(Nil)` if unavailable.

### `current_gid` — get group ID

```gleam
pub fn current_gid() -> Result(Int, Nil)
```

Get the numeric group ID (GID) of the current process. Returns `Error(Nil)` if unavailable.

### `lookup_user` — look up user by name

```gleam
pub fn lookup_user(name: String) -> Result(UserInfo, Nil)
```

Look up a user by name and return their information. Returns `Error(Nil)` if not found.

**Example:**

```gleam
case user.lookup_user("root") {
  Ok(info) -> io.println("Root UID: " <> int.to_string(info.uid))
  Error(Nil) -> io.println("User not found")
}
```

### `lookup_user_by_uid` — look up user by ID

```gleam
pub fn lookup_user_by_uid(uid: Int) -> Result(UserInfo, Nil)
```

Look up a user by numeric ID. Returns `Error(Nil)` if not found.

### `lookup_group` — look up group by name

```gleam
pub fn lookup_group(name: String) -> Result(GroupInfo, Nil)
```

Look up a group by name and return its information. Returns `Error(Nil)` if not found.

### `lookup_group_by_gid` — look up group by ID

```gleam
pub fn lookup_group_by_gid(gid: Int) -> Result(GroupInfo, Nil)
```

Look up a group by numeric ID. Returns `Error(Nil)` if not found.

### `current_user_groups` — get group memberships

```gleam
pub fn current_user_groups() -> Result(List(GroupInfo), Nil)
```

Get all groups that the current user belongs to. Returns `Error(Nil)` if unavailable.

## Cross-target notes

| Function       | BEAM | Node | Browser |
| -------------- | ---- | ---- | ------- |
| `current_user` | ✓    | ✓    | ❌      |
| `current_uid`  | ✓    | ✓    | ❌      |
| `lookup_user`  | ✓    | ✓    | ❌      |
| `lookup_group` | ✓    | ✓    | ❌      |

**Notes:**

- BEAM/Node: available on Unix; limited on Windows (UIDs/GIDs not applicable).
- Browser: no user info available.
- On systems without `/etc/passwd` (e.g., Windows), some functions may not work as expected.

## Examples

### Check if running as root

```gleam
import stardos/user

pub fn is_running_as_root() -> Bool {
  case user.current_uid() {
    Some(0) -> True
    _ -> False
  }
}

pub fn require_root() {
  case is_running_as_root() {
    True -> io.println("Running as root")
    False -> {
      io.println("ERROR: This command requires root privileges")
      process.exit(1)
    }
  }
}
```

### Log user info

```gleam
import stardos/user

pub fn log_user_info() {
  case user.current_user() {
    Some(info) -> {
      io.println("User: " <> info.name)
      case info.home {
        Some(home) -> io.println("Home: " <> home)
        None -> Nil
      }
    }
    None -> io.println("Could not determine user")
  }
}
```

## Summary

`stardos/user` provides read-only access to user and group information. Useful for privilege checking, logging, and permission inspection. User/group info comes from system sources (e.g., `/etc/passwd`, LDAP).
