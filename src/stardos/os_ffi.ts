import {
  Platform$Aix,
  Platform$Android,
  Platform$Darwin,
  Platform$FreeBsd,
  Platform$Illumos,
  Platform$Linux,
  Platform$OpenBsd,
  Platform$NetBsd,
  Platform$SunOs,
  Platform$Win32,
  Platform$Unknown,
  type Aix,
  type Android,
  type Darwin,
  type FreeBsd,
  type Illumos,
  type Linux,
  type OpenBsd,
  type NetBsd,
  type SunOs,
  type Win32,
  type Unknown
} from 'gleam:@stardos/stardos/os'

type Platform =
  | Aix
  | Android
  | Darwin
  | FreeBsd
  | Linux
  | Illumos
  | OpenBsd
  | NetBsd
  | SunOs
  | Win32
  | Unknown

const platformMap = {
  aix: Platform$Aix(),
  android: Platform$Android(),
  darwin: Platform$Darwin(),
  freebsd: Platform$FreeBsd(),
  illumos: Platform$Illumos(),
  linux: Platform$Linux(),
  openbsd: Platform$OpenBsd(),
  netbsd: Platform$NetBsd(),
  sunos: Platform$SunOs(),
  win32: Platform$Win32(),
  unknown: Platform$Unknown()
}

export function platform(): Platform {
  if (globalThis.Deno) {
    return platformMap[Deno.build.os] ?? Platform$Unknown()
  }
  if (globalThis.process?.platform) {
    return platformMap[process.platform] ?? Platform$Unknown()
  }
  switch (globalThis.navigator?.platform) {
    case 'MacIntel':
      return Platform$Darwin()
    case 'Win32':
      return Platform$Win32()
    case 'Linux x86_64':
      return Platform$Linux()
    default:
      return Platform$Unknown()
  }
}
