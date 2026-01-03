import gleam/io
import stardos/io as ios
import stardos/io/file

pub fn main() -> Nil {
  io.println("Hello from stardos!")
  use test_file <- file.at_path("test", given: ios.ReadOnly)
  let assert Ok(_test_file) = test_file
  io.println("test")
}
