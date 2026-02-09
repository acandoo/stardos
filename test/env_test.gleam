import stardos/env

pub fn var_set_var_test() {
  let var_name = "TEST_VAR"
  let var_value = "test_value"

  let prev_value = env.var(var_name)

  env.remove_var(var_name)

  // Set the variable
  env.set_var(var_name, var_value)

  // Retrieve the variable and check its value
  let assert Ok(value) = env.var(var_name)
  assert value == var_value

  case prev_value {
    Ok(prev) -> env.set_var(var_name, prev)
    Error(_) -> env.remove_var(var_name)
  }
}
