import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/string

/// A validator is a function that takes an input
/// and returns a tuple of `#(output, errors)`.
///
/// A validator always need to return an output of
/// the desired type. So default values are used for this.
///
/// When the errors list is empty, the validation is considered
/// successful.
pub type Validator(input, output, e) =
  fn(input) -> ValidatorResult(output, e)

/// The result of a validator
pub type ValidatorResult(output, e) =
  #(output, List(e))

/// Validate a value using a list of validators.
/// This runs all the validators in the list.
///
/// The initial input is passed to all validators.
/// All these validators must have the same input and output types.
/// If all the validators succeed, this will return the original input.
///
/// The returned errors contain all the failures.
///
/// e.g.
/// ```gleam
/// fn validator(input: String) {
///   use password <- valid.check(
///     input,
///     valid.all([password_has_numbers, password_has_symbols]),
///   )
///
///   valid.ok(out)
/// }
/// ```
pub fn all(validators: List(Validator(in, in, e))) -> Validator(in, in, e) {
  fn(input: in) -> ValidatorResult(in, e) {
    let all_errors =
      list.flat_map(validators, fn(validator) {
        let #(_, errors) = validator(input)
        errors
      })

    #(input, all_errors)
  }
}

/// Add a field validator to the validator pipeline
///
/// ```gleam
/// fn validator(input: Int) {
///   use out <- valid.check(input, valid.int_max(12, "Error"))
///   valid.ok(out)
/// }
/// ```
pub fn check(
  input input: in,
  validator validator: Validator(in, out, err),
  next next,
) {
  // First we collect the errors for the current validator
  let #(output, errors) = validator(input)

  // Then we run the next validator
  let #(next_output, next_errors) = next(output)

  #(next_output, errors |> list.append(next_errors))
}

/// A validator that fails with the given default and error.
pub fn fail(default, error) {
  #(default, [error])
}

/// e.g.
///
/// ```gleam
/// fn validator(input) {
///   use out <- valid.check(input, valid.int_max(12, "Cannot be higher than 12"))
///   valid.ok(out)
/// }
/// ```
pub fn int_max(max max: Int, error error: err) -> Validator(Int, Int, err) {
  fn(value: Int) {
    case value > max {
      True -> #(0, [error])
      False -> #(value, [])
    }
  }
}

/// e.g.
///
/// ```gleam
/// fn validator(input) {
///   use out <- valid.check(input, valid.int_min(12, "Must be more than 12"))
///   valid.ok(out)
/// }
/// ```
pub fn int_min(min min: Int, error error: err) -> Validator(Int, Int, err) {
  fn(value: Int) {
    case value < min {
      True -> #(0, [error])
      False -> #(value, [])
    }
  }
}

/// Validate that a value is not None.
/// The validator fails if None.
/// Runs the nested validator when Some.
/// This validator requires a `default` value to be provided.
///
///
/// ```gleam
/// fn validator(input) {
///   use out <- valid.check(input, valid.is_some("", valid.ok, "Input"))
///   valid.ok(out)
/// }
/// ```
pub fn is_some(
  default default: out,
  validator validator: Validator(in, out, err),
  error error: err,
) -> Validator(Option(in), out, err) {
  fn(option: Option(in)) {
    case option {
      None -> #(default, [error])
      Some(value) -> {
        validator(value)
      }
    }
  }
}

/// Runs the validator for each item in a list
///
///
/// ```gleam
/// fn validator(input) {
///   use out <- valid.check(input, valid.list_all(valid.string_is_not_empty("Empty")))
///   valid.ok(out)
/// }
/// ```
pub fn list_all(validator validator: Validator(in, out, err)) {
  fn(items) {
    let initial = #([], [])

    let accumulate = fn(acc, item) {
      let #(acc_out, acc_errors) = acc
      let #(output, errors) = validator(item)

      let next_output =
        acc_out
        |> list.append([output])

      let next_errors =
        acc_errors
        |> list.append(errors)

      let next_tuple = #(next_output, next_errors)

      case next_errors {
        [] -> list.Continue(next_tuple)
        _ -> list.Stop(next_tuple)
      }
    }

    list.fold_until(from: initial, over: items, with: accumulate)
  }
}

/// A validator that always succeeds
pub fn ok(output) {
  #(output, [])
}

/// Run a validator only when the value is Some
/// Otherwise succeed with None
pub fn optional(validator validator) {
  fn(maybe_input: Option(input)) {
    case maybe_input {
      None -> #(None, [])
      Some(input) -> {
        let #(output, errors) = validator(input)
        #(Some(output), errors)
      }
    }
  }
}

/// Validate if a string parses to a Boolean. Returns the Boolean if so.
pub fn string_is_bool(error error: err) -> Validator(String, Bool, err) {
  fn(value: String) {
    let lowered = string.lowercase(value)
    case lowered {
      "true" -> #(True, [])
      "false" -> #(False, [])
      _ -> #(False, [error])
    }
  }
}

/// This checks if a string follows a simple pattern `_@_`.
pub fn string_is_email(error error: err) -> Validator(String, String, err) {
  fn(value: String) {
    let pattern = "^([\\w\\d]+)(\\.[\\w\\d]+)*(\\+[\\w\\d]+)?@[\\w\\d\\.]+$"

    case regexp.from_string(pattern) {
      Ok(re) -> {
        case regexp.check(with: re, content: value) {
          True -> #(value, [])
          False -> #("", [error])
        }
      }
      Error(_) -> #("", [error])
    }
  }
}

/// Validate if a string parses to an Int. Returns the Int if so.
pub fn string_is_int(error error: err) -> Validator(String, Int, err) {
  fn(value: String) {
    case int.parse(value) {
      Ok(int) -> #(int, [])
      Error(_) -> #(0, [error])
    }
  }
}

/// Validate if a string parses to an Float. Returns the Float if so.
pub fn string_is_float(error error: err) -> Validator(String, Float, err) {
  fn(value: String) {
    case float.parse(value) {
      Ok(int) -> #(int, [])
      Error(_) ->
        case int.parse(value) {
          Ok(int) -> #(int.to_float(int), [])
          Error(_) -> #(0.0, [error])
        }
    }
  }
}

/// Validate if a string parses to an Float. Returns the Float if so.
pub fn string_is_float_strict(error error: err) -> Validator(String, Float, err) {
  fn(value: String) {
    case float.parse(value) {
      Ok(int) -> #(int, [])
      Error(_) -> #(0.0, [error])
    }
  }
}

/// Validate that a string is not empty
pub fn string_is_not_empty(error error: err) -> Validator(String, String, err) {
  fn(value: String) {
    case string.is_empty(value) {
      True -> #("", [error])
      False -> #(value, [])
    }
  }
}

/// Validate the min length of a string
pub fn string_min_length(
  min min: Int,
  error error: err,
) -> Validator(String, String, err) {
  fn(value: String) {
    let len = string.length(value)

    case len < min {
      True -> #("", [error])
      False -> #(value, [])
    }
  }
}

/// Validate the max length of a string
pub fn string_max_length(
  max max: Int,
  error error: err,
) -> Validator(String, String, err) {
  fn(value: String) {
    let len = string.length(value)

    case len > max {
      True -> #("", [error])
      False -> #(value, [])
    }
  }
}

/// Compose two validators.
/// This will only return the first error found.
///
/// e.g.
/// ```gleam
/// fn validator(input_name) {
///   use name <- valid.check(
///     input_name,
///     valid.string_min_length(2, "Min 2")
///       |> valid.then(valid.string_max_length(20, "Max 20")),
///   )
///
/// valid.ok(name)
/// }
/// ```
///
pub fn then(first_validator first_validator, second_validator second_validator) {
  fn(input) {
    case first_validator(input) {
      #(output, []) -> second_validator(output)
      #(output, errors) -> #(output, errors)
    }
  }
}

/// Run a validator
///
/// ```gleam
/// fn name_validator(input) {
///   use name <- valid.check(input, valid.string_min_length(2, "Min 2"))
///   valid.ok(name)
/// }
///
/// let result = "Sally"
/// |> valid.validate(name_validator)
///
/// result == Ok("Sally")
///
/// let result = ""
/// |> valid.validate(name_validator)
///
/// result == Error(["Min 2"])
/// ```
///
pub fn validate(input input: in, validator validator) {
  let #(output, errors) = validator(input)

  case errors {
    [] -> Ok(output)
    _ -> Error(errors)
  }
}
