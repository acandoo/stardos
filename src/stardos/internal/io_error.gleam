pub type PosixError {
  Eacces
  Eagain
  Ebadf
  Ebadmsg
  Ebusy
  Edeadlk
  Edeadlock
  Edquot
  Eexist
  Efault
  Efbig
  Eftype
  Eintr
  Einval
  Eio
  Eisdir
  Eloop
  Emfile
  Emlink
  Emultihop
  Enametoolong
  Enfile
  Enobufs
  Enodev
  Enolck
  Enolink
  Enoent
  Enomem
  Enospc
  Enosr
  Enostr
  Enosys
  Enotblk
  Enotdir
  Enotsup
  Enxio
  Eopnotsupp
  Eoverflow
  Eperm
  Epipe
  Erange
  Erofs
  Espipe
  Esrch
  Estale
  Etxtbsy
  Exdev
}

pub fn posix_to_string(error: PosixError) -> String {
  case error {
    Eacces -> "EACCES"
    Eagain -> "Eagain"
    Ebadf -> "Ebadf"
    Ebadmsg -> "Ebadmsg"
    Ebusy -> "Ebusy"
    Edeadlk -> "Edeadlk"
    Edeadlock -> "Edeadlock"
    Edquot -> "Edquot"
    Eexist -> "Eexist"
    Efault -> "Efault"
    Efbig -> "Efbig"
    Eftype -> "Eftype"
    Eintr -> "Eintr"
    Einval -> "Einval"
    Eio -> "Eio"
    Eisdir -> "Eisdir"
    Eloop -> "Eloop"
    Emfile -> "Emfile"
    Emlink -> "Emlink"
    Emultihop -> "Emultihop"
    Enametoolong -> "Enametoolong"
    Enfile -> "Enfile"
    Enobufs -> "Enobufs"
    Enodev -> "Enodev"
    Enolck -> "Enolck"
    Enolink -> "Enolink"
    Enoent -> "Enoent"
    Enomem -> "Enomem"
    Enospc -> "Enospc"
    Enosr -> "Enosr"
    Enostr -> "Enostr"
    Enosys -> "Enosys"
    Enotblk -> "Enotblk"
    Enotdir -> "Enotdir"
    Enotsup -> "Enotsup"
    Enxio -> "Enxio"
    Eopnotsupp -> "Eopnotsupp"
    Eoverflow -> "Eoverflow"
    Eperm -> "Eperm"
    Epipe -> "Epipe"
    Erange -> "Erange"
    Erofs -> "Erofs"
    Espipe -> "Espipe"
    Esrch -> "Esrch"
    Estale -> "Estale"
    Etxtbsy -> "Etxtbsy"
    Exdev -> "Exdev"
  }
}

pub type IoError {
  PosixError(error: PosixError)
  Eof
  Unknown(msg: String)
}
