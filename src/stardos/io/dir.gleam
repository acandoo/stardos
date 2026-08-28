pub opaque type Dir {
  Path(path: List(String))
  Inode(dirfd: DirFd)
}

type DirFd

pub fn current() -> Dir {
  Path(["."])
}

pub fn root() -> Dir {
  Path(["/"])
}

pub fn open()
