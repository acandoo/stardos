import {
  List,
  List$Empty,
  List$NonEmpty,
  Result$Error,
  Result$Ok,
  type Result
} from 'gleam'
import * as Dict from 'gleam:@gleam_stdlib/gleam/dict'
import {
  type JavaScript,
  JavaScriptRuntime$Bun,
  JavaScriptRuntime$Deno,
  JavaScriptRuntime$Node,
  JavaScriptRuntime$Unknown,
  Runtime$JavaScript
} from 'gleam:@stardos/stardos/env'

export function runtime(): JavaScript {
  if (globalThis.Bun) {
    const bunPath = process.execPath
    return Runtime$JavaScript(JavaScriptRuntime$Bun(bunPath))
  }
  if (globalThis.Deno) {
    const denoPath = Deno.execPath()
    return Runtime$JavaScript(JavaScriptRuntime$Deno(denoPath))
  }

  // Extra work is done to check for Node since other environments
  // (like Bun) also define `globalThis.process`.
  if (globalThis.process?.release?.name === 'node') {
    const nodePath = process.execPath
    return Runtime$JavaScript(JavaScriptRuntime$Node(nodePath))
  }

  // Fallback for unknown JavaScript runtimes.
  // At the moment browser/worker/edge runtimes are not supported.
  return Runtime$JavaScript(JavaScriptRuntime$Unknown)
}

export function program(): string {
  if (globalThis.Deno) {
    return new URL(Deno.mainModule).pathname
  }

  // note to self: see [github pr in argv](https://github.com/lpil/argv/pull/4/files)
  // can be improved
  if (globalThis.process?.argv) {
    return process.argv[1]
  }

  // since this function cannot error we return an empty string otherwise
  return globalThis.document?.location?.toString() ?? ''
}

export function args(): List {
  if (globalThis.process) {
    return List$NonEmpty(process.argv, List$Empty())
  }

  return List$Empty()
}

export function subArgs(): List {
  if (globalThis.Deno) {
    return List.fromArray(Deno.args)
  }
  if (globalThis.process) {
    // note to self: see [github pr in argv](https://github.com/lpil/argv/pull/4/files)
    // can be improved
    return List.fromArray(process.argv.slice(2))
  }

  return List.fromArray([])
}

export function getVar(key: string): Result {
  if (globalThis.Deno) {
    const value = Deno.env.get(key)
    if (value === undefined) {
      return Result$Error()
    }
    return Result$Ok(value)
  }
  if (globalThis.process) {
    const value = process.env[key]
    if (value === undefined) {
      return Result$Error()
    }
    return Result$Ok(value)
  }

  return Result$Error()
}

export function setVar(key: string, value: string): void {
  if (globalThis.Deno) {
    Deno.env.set(key, value)
  }
  if (globalThis.process) {
    process.env[key] = value
  }
}

export function getVars() {
  const envEntries = Object.entries(process.env ?? {})
  const dict = Dict.from_list(List.fromArray(envEntries))

  return dict
}

export function removeVar(key: string): void {
  if (globalThis.Deno) {
    Deno.env.delete(key)
  }
  if (globalThis.process) {
    delete process.env[key]
  }
}
