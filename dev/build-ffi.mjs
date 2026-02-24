import { glob } from 'node:fs/promises'
import { buildFile } from './common.mjs'

export async function runBuild() {
  const files = await glob('src/**/*.ts')
  for await (const file of files) {
    buildFile(file)
  }

  console.log('FFI build complete')
}

runBuild()
