import gleam/list
import internal/helpers
import shellout
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

pub fn sub_args_test() {
  // To prevent duplicate testing of runtimes, we inherit the runtime from the test runner
  let runtime_base_flag = helpers.runtime_flags()
  let empty_flag =
    list.append(
      ["run", "-m", "env/args_empty_fixture", "-t"],
      runtime_base_flag,
    )
  let foo_bar_flag =
    list.append(
      ["run", "-m", "env/args_foo_bar_fixture", "-t"],
      runtime_base_flag,
    )
    |> list.append(["foo", "bar"])
  let assert Ok(_) =
    shellout.command(run: "gleam", with: empty_flag, in: ".", opt: [])
  let assert Ok(_) =
    shellout.command(run: "gleam", with: foo_bar_flag, in: ".", opt: [])
}
