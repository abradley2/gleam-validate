import gleeunit
import gleeunit/should
import validate
import gleam/function
import gleam/string
import gleam/int
import gleam/list

pub fn main() {
  gleeunit.main()
}

type Form {
  Form(first_name: String, last_name: String, age: String)
}

pub type FirstName {
  FirstName(String)
}

pub type LastName {
  LastName(String)
}

pub type Age {
  Age(Int)
}

pub type ValidatedForm {
  ValidatedForm(FirstName, LastName, Age)
}

fn no_numbers(s: String) {
  case
    string.to_graphemes(s)
    |> list.all(fn(c) { string.contains("123456789", c) == False })
  {
    True -> validate.succeed(s)
    False -> validate.error("String must not contain numbers")
  }
}

fn string_non_empty(s: String) {
  case string.length(s) > 0 {
    True -> validate.succeed(s)
    False -> validate.error("Must not be empty")
  }
}

fn string_shorter_than(s: String, limit: Int) {
  case string.length(s) < limit {
    True -> validate.succeed(s)
    False -> validate.error("Must be less than " <> int.to_string(limit))
  }
}

fn is_int(s: String) {
  case int.base_parse(s, 10) {
    Ok(i) -> validate.succeed(i)
    Error(_) -> validate.error("Must be a number")
  }
}

fn is_positive(i: Int) {
  case i >= 0 {
    True -> validate.succeed(i)
    False -> validate.error("Must not be a negative number")
  }
}

pub fn small_form_test() {
  let form = Form(first_name: "Tony", last_name: "Bradley", age: "33")

  let validate_form =
    function.curry3(fn(first_name, last_name, age) {
      ValidatedForm(first_name, last_name, age)
    })

  let first_name_result =
    form.first_name
    |> string_non_empty
    |> validate.and_then(string_shorter_than(_, 100))
    |> validate.map(FirstName)
    |> validate.map_error(string.append("First Name Error: ", _))

  let last_name_result =
    form.last_name
    |> string_non_empty
    |> validate.and_then(string_shorter_than(_, 100))
    |> validate.map(LastName)
    |> validate.map_error(string.append("Last Name Error: ", _))

  let age_result =
    form.age
    |> is_int
    |> validate.and_then(is_positive)
    |> validate.map(Age)
    |> validate.map_error(string.append("Age Error: ", _))

  let validation_result =
    validate.succeed(validate_form)
    |> validate.and_map(first_name_result)
    |> validate.and_map(last_name_result)
    |> validate.and_map(age_result)

  should.be_ok(validation_result)
}

pub fn small_form_errors_test() {
  let form =
    Form(
      first_name: "TonyTonyTonyTonyTonyTonyTony9",
      last_name: "Bradley",
      age: "hello",
    )

  let validate_form =
    function.curry3(fn(first_name, last_name, age) {
      ValidatedForm(first_name, last_name, age)
    })

  let first_name_result =
    form.first_name
    |> validate.compose(no_numbers, [
      string_non_empty,
      string_shorter_than(_, 10),
    ])
    |> validate.map(FirstName)
    |> validate.map_error(string.append("First Name Error: ", _))

  let last_name_result =
    form.last_name
    |> string_non_empty
    |> validate.and_then(string_shorter_than(_, 100))
    |> validate.map(LastName)
    |> validate.map_error(string.append("Last Name Error: ", _))

  let age_result =
    form.age
    |> is_int
    |> validate.and_then(is_positive)
    |> validate.map(Age)
    |> validate.map_error(string.append("Age Error: ", _))

  let validation_result =
    validate.succeed(validate_form)
    |> validate.and_map(first_name_result)
    |> validate.and_map(last_name_result)
    |> validate.and_map(age_result)

  let #(first_err, rest_err) = should.be_error(validation_result)

  list.length(list.prepend(rest_err, first_err))
  |> should.equal(3)
}
