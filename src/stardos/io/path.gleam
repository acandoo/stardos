/// A path refers to a location on the filesystem.
pub type Path {
  Path(path: String)
}

pub fn absolute(path: String) -> Path {
  Path(path)
}
