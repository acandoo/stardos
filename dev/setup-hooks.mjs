import fs from 'node:fs/promises'
import path from 'node:path'

async function preCommitSetup() {
  const preCommitRepoPath = path.join('dev', 'hooks', 'pre-commit')
  await fs.chmod(preCommitRepoPath, 0o755)
  const preCommitHookPath = path.join('.git', 'hooks', 'pre-commit')
  const preCommitHookOldPath = path.join('.git', 'hooks', 'pre-commit.old')
  await fs.rename(preCommitHookPath, preCommitHookOldPath).catch(() => {})

  const relativeSymlinkPath = path.relative(
    path.join('.git', 'hooks'),
    preCommitRepoPath
  )
  await fs.symlink(relativeSymlinkPath, preCommitHookPath)
}

async function postMergeSetup() {
  const postMergeRepoPath = path.join('dev', 'hooks', 'post-merge')
  await fs.chmod(postMergeRepoPath, 0o755)
  const preCommitHookPath = path.join('.git', 'hooks', 'post-merge')
  const preCommitHookOldPath = path.join('.git', 'hooks', 'post-merge.old')
  await fs.rename(preCommitHookPath, preCommitHookOldPath).catch(() => {})

  const relativeSymlinkPath = path.relative(
    path.join('.git', 'hooks'),
    postMergeRepoPath
  )
  await fs.symlink(relativeSymlinkPath, preCommitHookPath)
}

preCommitSetup()
postMergeSetup()
