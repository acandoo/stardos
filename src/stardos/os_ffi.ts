export function platform(): string {
  if (globalThis.Deno) {
    return Deno.build.os ?? ''
  }
  if (globalThis.process?.platform) {
    return process.platform
  }
  switch (globalThis.navigator?.platform) {
    case 'MacIntel':
      return 'darwin'
    case 'Win32':
      return 'win32'
    case 'Linux x86_64':
      return 'linux'
    default:
      return ''
  }
}
