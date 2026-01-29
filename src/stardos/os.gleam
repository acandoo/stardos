//// The `os` module provides operating system-level
//// functioality, such as retrieving platform information.

/// The platform the program is running on.
/// Note that the efficacy of this function depends on
/// the underlying runtime's ability to accurately
/// report the operating system platform, so for example
/// NetBSD may be reported as Linux or Unknown in some environments.
/// 
/// This is semantically separate from the `runtime()` function
/// in the `env` module, which provides information about
/// the language runtime (e.g., Erlang, Node.js, Deno, etc.).
pub type Platform {
  /// IBM AIX
  Aix
  /// Android
  Android
  /// Apple macOS
  Darwin
  /// FreeBSD
  FreeBsd
  /// Illumos
  Illumos
  /// Linux
  Linux
  /// NetBSD
  NetBsd
  /// OpenBSD
  OpenBsd
  /// Solaris
  SunOs
  /// Microsoft Windows
  Win32
  /// Unknown or unsupported platform
  Unknown
}

/// Retrieves the operating system platform the program is running on.
/// 
/// ## Examples
/// 
/// Check if the platform is Windows:
/// ```gleam
/// let platform = platform()
/// case platform {
///   Win32 -> todo as "handle windows-specific logic"
///   _ -> todo as "handle other platforms"
/// }
/// ```
///
@external(javascript, "./os_ffi.mjs", "platform")
pub fn platform() -> Platform
