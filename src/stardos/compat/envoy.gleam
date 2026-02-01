import gleam/dict.{type Dict}
import stardos/env

@deprecated("Use var() from stardos/env instead")
pub fn get(name: String) -> Result(String, Nil) {
  env.var(name)
}

@deprecated("Use set_var() from stardos/env instead")
pub fn set(name: String, value: String) -> Nil {
  env.set_var(name, value)
}

@deprecated("Use remove_var() from stardos/env instead")
pub fn unset(name: String) -> Nil {
  env.remove_var(name)
}

@deprecated("Use vars() from stardos/env instead")
pub fn all() -> Dict(String, String) {
  env.vars()
}
