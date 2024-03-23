import validate_monadic.{type ErrorList} as validate
import validators
import gleam/string
import gleam/function
import gleam/result
import gleam/list

pub type Form {
  Form(
    first_name: String,
    first_name_errors: Result(Nil, ErrorList(String)),
    last_name: String,
    last_name_errors: Result(Nil, ErrorList(String)),
    age: String,
    age_errors: Result(Nil, ErrorList(String)),
  )
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

pub fn validate_form(form: Form) -> Result(ValidForm, Form) {
  let first_name_result =
    form.first_name
    |> validate.compose(validators.has_min_length(_, 1), [
      validators.does_not_contain(_, string.to_graphemes("123456789")),
      validators.does_not_contain(_, string.to_graphemes("=-+!@#$%^&*()_")),
    ])
    |> validate.map(ValidFirstName)
    |> validate.map_error(
      function.curry2(fn(err, form) {
        Form(
          ..form,
          first_name_errors: validate.and_also(
            form.first_name_errors,
            validate.error(err),
          ),
        )
      }),
    )

  let last_name_result =
    form.last_name
    |> validate.compose(validators.has_min_length(_, 1), [
      validators.does_not_contain(_, string.to_graphemes("123456789")),
      validators.does_not_contain(_, string.to_graphemes("=-+!@#$%^&*()_")),
    ])
    |> validate.map(ValidLastName)
    |> validate.map_error(
      function.curry2(fn(err, form) {
        Form(
          ..form,
          last_name_errors: validate.and_also(
            form.last_name_errors,
            validate.error(err),
          ),
        )
      }),
    )

  let age_result =
    form.age
    |> validators.is_int
    |> validate.and_then(validators.is_positive)
    |> validate.and_then(validators.is_less_than(_, 125))
    |> validate.map(ValidAge)
    |> validate.map_error(
      function.curry2(fn(err, form) {
        Form(
          ..form,
          age_errors: validate.and_also(form.age_errors, validate.error(err)),
        )
      }),
    )

  function.curry3(fn(first_name, last_name, age) {
    ValidForm(first_name, last_name, age)
  })
  |> validate.succeed
  |> validate.and_map(first_name_result)
  |> validate.and_map(last_name_result)
  |> validate.and_map(age_result)
  |> result.map_error(fn(set_errors) {
    let #(start, next) = set_errors
    list.fold(next, start(form), fn(form, set_err) { set_err(form) })
  })
}
