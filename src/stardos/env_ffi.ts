import { List, List$Empty, Result$Error, Result$Ok, type Result } from 'gleam'
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
    return List.fromArray(process.argv)
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

  return List$Empty()
}

function env(key: string): string {
  return (
    globalThis.Deno?.env.get(key) ?? globalThis.process?.env[key] ?? undefined
  )
}

export function getVar(key: string): Result {
  let keyValue = env(key)
  return keyValue === undefined ? Result$Error() : Result$Ok(keyValue)
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
  const env = globalThis.process?.env ?? globalThis.Deno?.env.toObject() ?? {}
  const envEntries = Object.entries(env)
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

export function cwd(): Result {
  if (globalThis.Deno) {
    return Result$Ok(Deno.cwd())
  }
  if (globalThis.process) {
    return Result$Ok(process.cwd())
  }
  return Result$Error()
}

export function setCwd(path: string): Result {
  // flatten into a single try-catch
  try {
    if (globalThis.Deno) {
      Deno.chdir(path)
      return Result$Ok()
    }
    if (globalThis.process) {
      process.chdir(path)
      return Result$Ok()
    }
  } finally {
    return Result$Error()
  }
}
