# Design Rationale

A lot of opinionated decisions were made in developing this library, and this file tracks these decisions over time.

## Inert futures / Core concurrency

The fundamental problem with asynchronous programming across the Erlang and JavaScript runtime is how much differently concurrency is handled in operations. On JavaScript, functions are "colored" in that they can return synchronously or return a live Promise that can be `await`ed, while on Erlang, all operations are synchronous with concurrency/parallelism abstracted through "processes".

If you follow the Erlang model of processes, functions like reading files would block the JavaScript event loop, unless you make use of Node.js Worker Threads or Web Workers, and somehow pass an anonymous function into the thread while accounting for references to data outside the function's scope, etc etc. Making use of Promises for concurrent execution is also a non-option, as operations would still block the event loop making concurrency effectively useless. If you follow the JavaScript model of Promises, since they're live you'd end up spawning a process indefinitely for every asynchonous operation and add message handlers so that multiple awaiters can obtain the result.

An inert future is likely the best tradeoff for both the Erlang and JavaScript runtimes. Disregarding messages, cancellability, etc., a Future is a function that runs the desired operation on Erlang, and a function that returns a Promise on JavaScript. Inert futures would be chained by making a wrapper function. Creating a bunch of anonymous functions is assumed to be much cheaper than live constructing a Promise chain or spawning a bunch of processes.

Erlang is more than just parallel processes, though; message passing is something that's not as easily replicable on JavaScript, and would likely use an async generator or similar.

One of the main selling points of Gleam and OTP is the Actor framework, where actor state is pseudo-mutated and effects are spawned by messages passed to actors. This actor approach feels core to Gleam's identity, if it is to develop a core asynchronous primitive; so I don't want to stray too far away in terms of the patterns promoted. There's still a lot WIP, but some combination of Streams and Tasks with some sort of accumulator will likely be what ends up allowing for an actor-like model.

## Module split

In terms of where OS resources are handled, this library is most heavily inspired by Rust's `std` crate. While obviously allowing for a lot more control, Rust is probably the closest language to take API inspiration from due to its focus on explicitness and not hiding inherent complexity.

Larger modules are generally preferred over smaller modules though, so maybe I could consider a Go-like approach of putting everything under an `os` namespace. The line gets pretty blurry anyways, with things like TTY settings, home & temp directories, current working directory, thread and process spawning, etc.

## I/O read/write, file opening

When it comes to Gleam, there's only one way to make I/O reads/writes type-safe: a separate reader and writer. I wish you could set a return type to a "subtype", but that would lead to an entirely different language and thus be an unsuitable API for Gleam. A separate reader and writer would also lead to three different functions for opening a file (read-only, write-only, read-write to avoid TOCTOU for separate function calls in Gleam), and combined with write behavior (append or absolute, truncate or no truncate), existing file behavior (O_CREAT, O_EXCL), disk write behavior (O_SYNC, though this could be excluded), directory encounter behavior (O_DIRECTORY), and flags only available on JavaScript, there's not really a super elegant way to go about this.

All these optional flags make a builder pattern really enticing, but the pipe operator doesn't behave all that well with use syntax, requiring a curried function. I want the API to use the `use` syntax (ha ha..) since it would allow for forcing file descriptors to close once they're opened and feel like JavaScript/C# `using` syntax.

However! You _could_ use pipe syntax within a function argument body. O_TRUNC is a nasty edge case though, since the flag only applies to write streams. Either add add another argument to the function or ignore it in some FileOpenOptions type, or make separate types for reading and writing, or just pass in every branch of permutation as a separate argument atp and forget about it...

In most I/O APIs, there's also an implicit "cursor" that gets moved as you read the file, but since that feels object-oriented and hides intent from the user and you can (in most cases) reposition the cursor manually for reads, there's not really much point in having it. What makes the cursor complicated is that if you want a fully type-safe API you wouldn't have a way to express absolute cursor position in a write operation on an append-only stream, which would lead to **three** types (reader, writer, appender) and **five** open functions (open_read, open_write, open_append, open_rw/open_read_write, open_ra/open_read_append).

> gah i wish gleam had function overloading...

### Origin Private File System (OPFS)

A bit of a side track, but I think supporting OPFS would be nice for truly isomorphic code. Its API is more _ad hoc_ (in part because TOCTOU only occurs between threads _you_ control), and it being exclusively Promise-based also justifies giving up synchronous execution entirely for I/O-related functionality, which means the functions don't have to be prefixed with async\_\*. Though Web Workers support synchronous file handles, which are faster,, something to think about.

The API also only has one option: whether to create a new file (aka O_CREAT). What level of access to file opening is TBD.
