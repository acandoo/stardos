import path from 'node:path'
import { rolldown } from 'rolldown'

const projectName = 'stardos'
const baseDir = 'src'

/**
 * @param {string} file
 * @returns {Promise<void>}
 */
export async function buildFile(file) {
  const newFileName = file.slice(0, -3) + '.mjs'
  console.log(`Building ${newFileName}...`)
  let bundle
  try {
    bundle = await rolldown({
      input: file,
      platform: 'node',
      plugins: [importRewriter, relativeImportRewriter],
      experimental: {
        attachDebugInfo: 'none'
      }
    })

    await bundle.write({
      file: newFileName,
      banner: `// This file is generated from ${file}. Do not edit it directly.\n`
    })
  } catch (error) {
    console.error(`Error building ${file}: ${error}`)
  }
  if (bundle) {
    await bundle.close()
  }
}

/**
 * @type {import('rolldown').Plugin}
 */
const importRewriter = {
  name: 'import-rewriter',
  resolveId: {
    filter: {
      id: /^gleam(:@.+)?$/
    },
    handler(source, importer) {
      // The absolute path to the module being imported
      let fullPath

      if (source.startsWith(`gleam:@${projectName}/`)) {
        const prefixLength = `gleam:@${projectName}/`.length
        const modulePath = source.slice(prefixLength)
        fullPath = path.resolve(`${baseDir}/${modulePath}.mjs`)
      } else if (source.startsWith('gleam:@')) {
        const prefixLength = 'gleam:@'.length
        const modulePath = source.slice(prefixLength)
        fullPath = path.resolve(`${modulePath}.mjs`)
      } else {
        // import path should be 'gleam'
        fullPath = path.resolve('src/gleam.mjs')
      }

      const resolveDir = importer ? path.dirname(importer) : process.cwd()
      let relPath = path.relative(resolveDir, fullPath)
      if (!relPath.startsWith('.')) {
        relPath = `./${relPath}`
      }

      return {
        id: relPath.replace(/\\/g, '/'),
        external: true
      }
    }
  }
}

/**
 * Rewrites extension-less and .ts relative imports to .mjs
 * and keeps them external so non-gleam user imports are not bundled.
 *
 * @type {import('rolldown').Plugin}
 */
const relativeImportRewriter = {
  name: 'relative-import-rewriter',
  resolveId: {
    filter: {
      id: /^\..*/
    },
    handler(source) {
      let id = source.replace(/\\/g, '/')
      const extension = path.extname(id)

      if (!extension) {
        id = `${id}.mjs`
      } else if (extension === '.ts') {
        id = `${id.slice(0, -3)}.mjs`
      }

      return {
        id,
        external: true
      }
    }
  }
}
