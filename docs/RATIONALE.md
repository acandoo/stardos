# Design Rationale

A lot of opinionated decisions were made in developing this library, and this file tracks these decisions over time.

## Inert futures

The fundamental problem with asynchronous programming across the Erlang and JavaScript runtime is how differently concurrency is handled in operations. On JavaScript, functions are "colored" in that they can either return synchronously or return a live Promise that can be `await`ed or `.then`ed; on Erlang, all operations are synchronous with concurrency/parallelism abstracted through "processes".

If you follow the Erlang model of processes where all operations are synchronous, functions like reading files would block the JavaScript event loop, unless you make use of Node.js Worker Threads or Web Workers, and somehow pass an anonymous function into the thread while accounting for references to data outside the function's scope, etc etc. Making use of Promises to batch operations to run concurrently on the microtask queue is also a non-option, as operations would still block the event loop, making concurrency effectively useless.

On the other hand, if you follow the JavaScript model of Promises, you'd end up spawning a process indefinitely for every asynchonous operation and add message handlers so that multiple awaiters can obtain the result. Every operation would become a zombie process on Erlang.

An inert future is likely the best tradeoff for both the Erlang and JavaScript runtimes. Disregarding cancellability, a Future is a function that runs the desired operation on Erlang, and a function that returns a Promise on JavaScript. Inert futures are chained by making a wrapper function. Creating a bunch of anonymous functions is assumed to be much cheaper than live constructing a Promise chain or spawning a bunch of processes. On the flip side, this means either exposing memoization to the developer for cases where multiple Tasks share a common execution of a future, or allowing Tasks to be awaited within futures. This library permits both: `future.memo` (and its iterator cousin `stream.memo`) if you don't want the memoized functions' panic boundaries/execution to exist separate of dependent tasks, and `task.await` in case you do. However, tasks that use `task.await` within their future definition will carry over panics from the awaited task.

## Task cancellation

One of the advantages of Gleam is value-based errors, and part of figuring out the Future/Task model is finding where the boundary between errors and panics should lie. Early on, a split had to be made between Tasks and AbortableTasks, as AbortableTasks have the overhead of an AbortController on JavaScript. Ultimately, aborting a Task is not fatal, since it doesn't use a built-in panicking keyword, while using `assert` or `panic` within a future spawned by a Task is fatal to the task and upstream Tasks dependent on that task. This mirrors the behavior of calling actors, as they also crash the process if the actor doesn't respond within time.

Since code is modeled through creating futures, Tasks become analogous to processes on Erlang and Promises on JavaScript. Processes can be cancelled on Erlang, while Promises' results can be disregarded through a wrapper Promise.

## `Stream` type signature

Just like the Future abstraction, laziness is the key to minimizing the number of processes in Erlang and live changes in the JavaScript Promise chain. The Stream design follows that directive by making all streams "cold", reusing the Task boundary to indicate execution.

For various cases where the size of the stream will be known at once without consuming the previous items, an abstraction wouldn't be needed; a `Future(List(a))` or `List(Future(a))` (or even a `Future(List(Future(a)))`!) would suffice.

Erlang is more than just parallel processes, though; message passing is something that's not as easily replicable on JavaScript, and would likely use an async generator or similar.

One of the main selling points of Gleam and OTP is the Actor framework, where actor state is pseudo-mutated and effects are spawned by messages passed to actors. This actor approach feels core to Gleam's identity, if it is to develop a core asynchronous primitive; so this library doesn't stray too far away in terms of the patterns promoted.

With the existing primitives created, an Actor can be replicated by combining a channel (which wraps a Stream) with a Task.

## Module split

In terms of where OS resources are handled, this library is most heavily inspired by Rust's `std` crate. While it obviously allows for a lot more control, Rust is probably the closest language to take API inspiration from due to its similar hierarchical module split, its focus on explicitness, and not hiding inherent complexity.

Larger modules are generally preferred over smaller modules though, so maybe I could consider a Go-like approach of putting everything under an `os` namespace. The line gets pretty blurry anyways, with things like TTY settings, home & temp directories, current working directory, process spawning, etc.

## I/O read/write, file opening

When it comes to Gleam, there's only one way to make I/O reads/writes type-safe: a separate reader and writer. I wish you could set a return type to a "subtype", but that would lead to an entirely different language and thus be an unsuitable API for Gleam. A separate reader and writer would also lead to three different functions for opening a file (read-only, write-only, read-write to avoid TOCTOU for separate function calls in Gleam), and combined with write behavior (append or absolute, truncate or no truncate), existing file behavior (O_CREAT, O_EXCL), disk write behavior (O_SYNC, though this could be excluded), directory encounter behavior (O_DIRECTORY), and flags only available on JavaScript, there's not really a super elegant way to go about this.

All these optional flags make a builder pattern really enticing.

In most I/O APIs, there's also an implicit "cursor" that gets moved as you read the file, but since that creates a state object and hides intent from the user and you can (in most cases) reposition the cursor manually for reads, there's not really much point in having it. What makes the cursor complicated is that if you want a fully type-safe API you wouldn't have a way to express absolute cursor position in a write operation on an append-only stream, which would lead to **three** types (reader, writer, appender) and **five** open functions (open_read, open_write, open_append, open_rw/open_read_write, open_ra/open_read_append).

### Origin Private File System (OPFS)

A bit of a side track, but I think supporting OPFS would be nice for truly isomorphic code. Its API is more _ad hoc_ (in part because TOCTOU only occurs between threads _you_ control), and it being exclusively Promise-based also justifies giving up synchronous execution entirely for I/O-related functionality, which means the functions don't have to be prefixed with async\_\*. Though Web Workers support synchronous file handles, which are faster,, something to think about.

The API also only has one option: whether to create a new file (aka O_CREAT). What level of access to file opening is TBD.
