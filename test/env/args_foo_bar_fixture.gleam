//// This module is run by env_test.gleam

import gleam/io
import gleam/list
import stardos/env

pub fn main() -> Nil {
  assert env.sub_args() == ["foo", "bar"]
  list.each(env.args(), io.println)
}
