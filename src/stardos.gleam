import gleam/io
import gleam/list
import stardos/env

pub fn main() -> Nil {
  list.each(env.args(), io.println)
}
