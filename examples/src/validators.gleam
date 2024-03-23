import gleam/string
import gleam/int
import validate_monadic.{type Validation} as validate

pub fn is_int(value: String) -> Validation(Int, String) {
  case int.base_parse(value, 10) {
    Ok(pased_value) -> validate.succeed(pased_value)
    Error(_) -> validate.error("Not an integer")
  }
}

pub fn is_positive(value: Int) -> Validation(Int, String) {
  case value >= 0 {
    True -> validate.succeed(value)
    False -> validate.error("Not a positive integer")
  }
}

pub fn is_greater_than(value: Int, min: Int) -> Validation(Int, String) {
  case value > min {
    True -> validate.succeed(value)
    False -> validate.error("Not greater than " <> int.to_string(min))
  }
}

pub fn is_less_than(value: Int, max: Int) -> Validation(Int, String) {
  case value < max {
    True -> validate.succeed(value)
    False -> validate.error("Not less than " <> int.to_string(max))
  }
}

pub fn has_min_length(
  value: String,
  min_length: Int,
) -> Validation(String, String) {
  case string.length(value) >= min_length {
    True -> validate.succeed(value)
    False -> validate.error("Not long enough")
  }
}

pub fn has_max_length(
  value: String,
  max_length: Int,
) -> Validation(String, String) {
  case string.length(value) <= max_length {
    True -> validate.succeed(value)
    False -> validate.error("Too long")
  }
}

pub fn does_not_contain(
  value: String,
  forbidden_list: List(String),
) -> Validation(String, String) {
  case forbidden_list {
    [] -> validate.succeed(value)
    [forbidden, ..rest] ->
      case string.contains(value, forbidden) {
        True -> validate.error("Contains forbidden value -> " <> forbidden)
        False -> does_not_contain(value, rest)
      }
  }
}
