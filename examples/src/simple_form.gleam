import validate_monadic.{type Validation} as validate
import validators
import gleam/string
import gleam/function

pub type Form {
  Form(first_name: String, last_name: String, age: String)
}

pub type ValidFirstName {
  ValidFirstName(String)
}

pub type ValidLastName {
  ValidLastName(String)
}

pub type ValidAge {
  ValidAge(Int)
}

pub type ValidForm {
  ValidForm(ValidFirstName, ValidLastName, ValidAge)
}

pub fn validate_form(form: Form) -> Validation(ValidForm, String) {
  let first_name_result =
    form.first_name
    |> validate.compose(validators.has_min_length(_, 1), [
      validators.does_not_contain(_, string.to_graphemes("123456789")),
      validators.does_not_contain(_, string.to_graphemes("=-+!@#$%^&*()_")),
    ])
    |> validate.map(ValidFirstName)
    |> validate.map_error(string.append("First name error: ", _))

  let last_name_result =
    form.last_name
    |> validate.compose(validators.has_min_length(_, 1), [
      validators.does_not_contain(_, string.to_graphemes("123456789")),
      validators.does_not_contain(_, string.to_graphemes("=-+!@#$%^&*()_")),
    ])
    |> validate.map(ValidLastName)
    |> validate.map_error(string.append("Last name error: ", _))

  let age_result =
    form.age
    |> validators.is_int
    |> validate.and_then(validators.is_positive)
    |> validate.and_then(validators.is_less_than(_, 125))
    |> validate.map(ValidAge)
    |> validate.map_error(string.append("Age error: ", _))

  function.curry3(fn(first_name, last_name, age) {
    ValidForm(first_name, last_name, age)
  })
  |> validate.succeed
  |> validate.and_map(first_name_result)
  |> validate.and_map(last_name_result)
  |> validate.and_map(age_result)
}
