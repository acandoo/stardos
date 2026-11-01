import stardos/internal/dir_base.{type Dir}
import stardos/io.{type IoError}
import stardos/io/path.{type Path}

pub fn current() -> Dir {
  dir_base.Path(["."])
}

pub fn root() -> Dir {
  dir_base.Path(["/"])
}

pub fn hold(_path: Path) -> Result(Dir, IoError) {
  Ok(dir_base.Path(["/"]))
}
