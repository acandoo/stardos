import gleam/bool
import gleam/string
import stardos/os

pub fn join(parts: List(String)) -> String {
  use <- bool.guard(when: parts == [], return: ".")
  case os.platform() {
    os.Win32 -> parts |> string.join("\\")
    // All other platforms use the POSIX convention
    _ -> parts |> string.join("/")
    // note to self: check through Node's [implementation]
    // (https://github.com/nodejs/node/blob/v25.5.0/lib/path.js)
    // for parity, this is not comprehensives
  }
}
