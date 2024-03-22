import gleam/option.{type Option}
import gleam/list

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
  case validation {
    Ok(a) -> Ok(map_fn(a))
    Error(err) -> Error(err)
  }
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

pub fn and_then(
  over validation: Validation(a, error),
  bind bind_fn: fn(a) -> Validation(b, error),
) -> Validation(b, error) {
  case validation {
    Ok(a) -> {
      case bind_fn(a) {
        Ok(b) -> Ok(b)
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
