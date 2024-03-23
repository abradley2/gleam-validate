import simple_form
import gleam/io

pub fn main() {
  let simple_form_result =
    simple_form.validate_form(simple_form.Form(
      first_name: "9!",
      last_name: "Doe",
      age: "10",
    ))

  io.debug(simple_form_result)

  Nil
}
