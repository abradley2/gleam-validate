import gleam/list
import gleam/result

pub type Validation(validated, error) =
  Result(validated, ErrorList(error))

pub type ErrorList(error) =
  #(error, List(error))

pub fn error(err: error) -> Validation(a, error) {
  Error(#(err, []))
}

pub fn succeed(a) -> Validation(a, error) {
  Ok(a)
}

pub fn map(
  over validation: Validation(a, error),
  with map_fn: fn(a) -> b,
) -> Validation(b, error) {
  result.map(validation, map_fn)
}

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

pub fn and_also(
  validation_a: Validation(a, error),
  validation_b: Validation(a, error),
) -> Validation(a, error) {
  case validation_a, validation_b {
    Ok(a), Ok(_) -> Ok(a)
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

pub fn and_then(
  over validation: Validation(a, error),
  bind bind_fn: fn(a) -> Validation(b, error),
) -> Validation(b, error) {
  result.then(validation, bind_fn)
}

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
