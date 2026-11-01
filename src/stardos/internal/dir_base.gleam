pub type Dir {
  Path(path: List(String))
  Inode(dirfd: DirFd)
}

pub type DirFd
