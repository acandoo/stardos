import { buildOptions } from './common.mjs'
import esbuild from 'esbuild'

async function watch() {
  const ctx = await esbuild.context(buildOptions)

  await ctx.watch()

  console.log('Watching for changes...')
}

watch()
