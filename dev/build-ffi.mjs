import { glob } from 'node:fs/promises'
import { buildFile } from './common.mjs'

if (!process.argv[1] == 'dev/build-ffi.mjs') {
  console.error('This script should only be run from the project root')
  process.exit(1)
}

export async function runBuild() {
  const files = await glob('src/**/*.ts')
  for await (const file of files) {
    buildFile(file)
  }

  console.log('FFI build complete')
}

runBuild()
