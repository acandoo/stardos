import gleam/list
import stardos/concurrent/stream.{type Stream}

pub type Channel(a) {
  Channel(stream: Stream(a), send: fn(a) -> Nil)
}

pub fn new() -> Channel(a) {
  let #(stream, send) = stream.capture(fn(sender) { sender })
  Channel(stream:, send:)
}

pub fn from(values: List(a)) -> Channel(a) {
  let #(stream, send) =
    stream.capture(fn(sender) {
      values
      |> list.each(sender)
      sender
    })
  Channel(stream:, send:)
}
