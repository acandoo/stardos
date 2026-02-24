import fs from 'node:fs/promises'
import { buildFile } from './common.mjs'
import { runBuild } from './build-ffi.mjs'

async function watch() {
  await runBuild()
  const watcher = fs.watch('src', { recursive: true })
  console.log('Watching for changes in src/...')
  for await (const event of watcher) {
    if (event.filename?.endsWith('.ts')) {
      console.log(`Detected event in ${event.filename}: ${event.eventType}`)
      if (event.eventType === 'change')
        buildFile(`src/${event.filename}`).then(() =>
          console.log(`Rebuilt ${event.filename}`)
        )
      handleCreateOrDelete(event)
    }
  }
}

async function handleCreateOrDelete(event) {
  try {
    await fs.access(`src/${event.filename}`)
    buildFile(`src/${event.filename}`)
  } catch {
    const jsFileName = `src/${event.filename.slice(0, -3)}.mjs`
    try {
      await fs.rm(jsFileName)
      console.log(`Deleted ${jsFileName}`)
    } catch (err) {
      console.error(`Error deleting ${jsFileName}: ${err}`)
      console.error(
        `File ${jsFileName} may have already been deleted or is inaccessible.`
      )
    }
  }
}

watch()
