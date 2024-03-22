# Monadic Validation in Gleam!

```sh
gleam add validate
```

# Usage

This module is the minimal set of functions around a single type alias for `Result` so it may 
be used as a "validation monad".

```gleam
pub type Validation(validated, error) =
  Result(validated, ErrorList(error))

pub type ErrorList(error) =
  #(error, List(error))
```

For `Validation`, we implement [Functor](https://en.wikipedia.org/wiki/Functor),
[Applicative](https://en.wikipedia.org/wiki/Applicative_functor), 
and [Monad](https://en.wikipedia.org/wiki/Monad_(functional_programming)). This is really all you need for
type safe form validation.

More convenient abstractions can be built on top of this.

Check out the tests for examples around usage:
```gleam
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
    |> is_postive_int
    |> validate.map(Age)
    |> validate.map_error(string.append("Age Error: ", _))

  let validation_result =
    validate.succeed(validate_form)
    |> validate.and_map(first_name_result)
    |> validate.and_map(last_name_result)
    |> validate.and_map(age_result)

  should.be_ok(validation_result)
}
```

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
