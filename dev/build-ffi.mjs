import esbuild from 'esbuild'
import { buildOptions } from './common.mjs'

async function build() {
  await esbuild.build(buildOptions)

  console.log('FFI build complete')
}

build()
