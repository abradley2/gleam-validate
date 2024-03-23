import gleam/list
import gleam/result

/// Simple type alias over a Result with a *non-empty* list off generic errors
/// for the Error branch. The non-empty list is important here. For validation we must
/// represent a Result type that can have multiple errors, but we must avoid allowing 
/// something like `Error([])` in which we can have an error branch but no errors!
pub type Validation(validated, error) =
  Result(validated, ErrorList(error))

/// Simple type alias for a non-empty list. A non-empty list is just a structure containing the
/// first item of the list, followed by the rest of the list. You can find a more 
/// useful implementation [here](https://hexdocs.pm/non_empty_list/non_empty_list.html#NonEmptyList)
/// . For the purposes of not including an extra dependency, we just use a tuple here.
pub type ErrorList(error) =
  #(error, List(error))

/// Convenience function for lifting a single error into our non-empty `ErrorList` type.
pub fn error(err: error) -> Validation(a, error) {
  Error(#(err, []))
}

/// Convenience function for lifting a value into our validation type's `Ok` branch. As with other methods
/// in this module, it is just an alias for a `Result` type method. 
pub fn succeed(a) -> Validation(a, error) {
  Ok(a)
}

/// Map a validation type to another type. This is often useful to nest the result of a validation 
/// into a "ValidatedType". This is just an alias over `result.map`
/// 
/// ```gleam
///   pub type ValidatedLastName {
///     ValidatedLastName(String)
///   }
/// 
///   // ...
/// 
///   let last_name_result =
///     form.last_name
///       |> string_non_empty
///       |> validate.map(ValidatedLastName)
/// ```
pub fn map(
  over validation: Validation(a, error),
  with map_fn: fn(a) -> b,
) -> Validation(b, error) {
  result.map(validation, map_fn)
}

/// Map over all the errors for a validation result.
/// This is very useful for cases where you have re-usable validators with generic error messages,
/// and you wish to specify the errors are associated with a specific field
/// 
/// ```gleam
/// 
/// let validation_result =
///   raw_field
///     |> validate.compose(no_numbers, [shorter_than_10])
///     |> validate.map_error(string.append("Field Name Error: ", _))
/// ```
pub fn map_error(
  over validation: Validation(a, error_a),
  with map_fn: fn(error_a) -> error_b,
) -> Validation(a, error_b) {
  case validation {
    Ok(v) -> Ok(v)
    Error(#(head, rest)) -> {
      Error(#(map_fn(head), list.map(rest, map_fn)))
    }
  }
}

/// Compose together multiple validations. This combines the errors of all validations that fail,
/// and does not stop at the first failure. Takes the input to be validated as the first argument,
/// then a non-empty list of unary functions that transform the same input type into a `Validation`
/// result of the same type.
/// 
/// 
/// ```gleam
/// 
/// let validation_result =
///   raw_field
///     |> validate.compose(no_numbers, [shorter_than_10, no_symbols, no_whitespace])
/// ```
pub fn compose(
  input: a,
  validation: fn(a) -> Validation(b, error),
  validations: List(fn(a) -> Validation(b, error)),
) -> Validation(b, error) {
  list.fold(validations, validation(input), fn(acc, cur) {
    and_also(acc, cur(input))
  })
}

/// Combine two validation results into one. This is mainly for merging errors. The `Ok `branch of the
/// last validation supplied will be the returned `Ok` branch. This is used internally by `compose`
pub fn and_also(
  validation_a: Validation(a, error),
  validation_b: Validation(a, error),
) -> Validation(a, error) {
  case validation_a, validation_b {
    Ok(_), Ok(a) -> Ok(a)
    Error(#(err_a_head, err_a_rest)), Error(#(err_b_head, err_b_rest)) -> {
      Error(#(
        err_a_head,
        list.concat([err_a_rest, list.prepend(err_b_rest, err_b_head)]),
      ))
    }
    Error(err), _ -> Error(err)
    _, Error(err) -> Error(err)
  }
}

/// Specify a validation that will run after a given validation, using its result. This is very
/// useful for validations that need to run after a transform is attempted. Note that `and_then`
/// does not _collect_ errors as `compose` does, it will stop at the first error.
/// 
/// ```gleam
/// let age_result =
///   form.age_string
///   |> is_parsable_int
///   |> validate.and_then(int_less_than(_, 101))
/// ```
/// 
/// It can easily be used in conjuction with `compose`
/// 
/// ```gleam
/// let age_result =
///   form.age_string
///   |> is_parsable_int
///   |> validate.and_then(
///     validate.compose(int_less_than(_, 101), [int_greater_than(_, 0)])
///   )
/// ```
pub fn and_then(
  over validation: Validation(a, error),
  bind bind_fn: fn(a) -> Validation(b, error),
) -> Validation(b, error) {
  result.then(validation, bind_fn)
}

/// Used to create applicative chains of validation. This is very important for combining validation
/// of fields into the validation of an entire form.
/// 
/// ```gleam
/// let validate_form = function.curry3(fn (
///     ValidFirstName,
///     ValidLastName,
///     ValidAge
///   ) {
///     ValidForm(ValidFirstName, ValidLastName, ValidAge)
///   })
/// 
/// let validation_result =
///   validate.succeed(validate_form)
///   |> validate.and_map(first_name_result)
///   |> validate.and_map(last_name_result)
///   |> validate.and_map(age_result)
/// ```
pub fn and_map(
  prev prev_validation: Validation(fn(a) -> b, error),
  next validation: Validation(a, error),
) -> Validation(b, error) {
  case prev_validation {
    Ok(apply) -> {
      case validation {
        Ok(a) -> Ok(apply(a))
        Error(err) -> Error(err)
      }
    }
    Error(#(prev_err_head, prev_err_rest)) -> {
      case validation {
        Ok(_) -> {
          Error(#(prev_err_head, prev_err_rest))
        }
        Error(#(next_err_head, next_err_rest)) -> {
          Error(#(
            prev_err_head,
            list.flatten([
              prev_err_rest,
              list.prepend(next_err_rest, next_err_head),
            ]),
          ))
        }
      }
    }
  }
}
