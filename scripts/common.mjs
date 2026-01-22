import { globSync } from 'glob'
import path from 'node:path'

const projectName = 'stardos'
const baseDir = 'src'
const files = globSync(`${baseDir}/**/*.ts`)

export const buildOptions = {
  entryPoints: files,
  outdir: baseDir,
  outbase: baseDir,
  format: 'esm',
  platform: 'node',
  outExtension: { '.js': '.mjs' },
  bundle: true,
  plugins: [
    {
      name: 'import-rewriter',
      setup(build) {
        build.onResolve({ filter: /^gleam(:@.+)?$/ }, (args) => {
          const { path: importPath, resolveDir } = args
          let fullPath

          if (importPath.startsWith(`gleam:@${projectName}/`)) {
            const prefixLength = `gleam:@${projectName}/`.length
            const modulePath = importPath.slice(prefixLength)
            fullPath = path.resolve(`${baseDir}/${modulePath}.mjs`)
          } else if (importPath.startsWith('gleam:@')) {
            const prefixLength = 'gleam:@'.length
            const modulePath = importPath.slice(prefixLength)
            fullPath = path.resolve(`${modulePath}.mjs`)
          } else {
            // import path should be 'gleam'
            fullPath = path.resolve('src/gleam.mjs')
          }

          const relPath = path.relative(resolveDir, fullPath)
          return {
            path: relPath.replace(/\\/g, '/'),
            external: true
          }
        })
      }
    }
  ]
}
