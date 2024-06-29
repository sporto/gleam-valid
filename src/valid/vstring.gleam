import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/string
import valid/vcommon

fn is_not_empty_check(value: String) -> Option(String) {
  case string.is_empty(value) {
    True -> None

    False -> Some(value)
  }
}

/// Validate if a string is not empty
pub fn is_not_empty(error: e) {
  vcommon.custom(error, is_not_empty_check)
}

/// Validate if a string parses to an Int. Returns the Int if so.
pub fn is_int(error: e) {
  vcommon.custom(error, fn(value) {
    int.parse(value)
    |> option.from_result
  })
}

/// Validate if a string parses to an Float. Returns the Float if so.
pub fn is_float(error: e) {
  vcommon.custom(error, fn(value) {
    float.parse(value)
    |> option.from_result
  })
}

fn is_email_check(value: String) -> Option(String) {
  let pattern = "^[\\w\\d]+@[\\w\\d\\.]+$"

  case regex.from_string(pattern) {
    Ok(re) -> {
      case regex.check(with: re, content: value) {
        True -> Some(value)

        False -> None
      }
    }
    Error(_) -> None
  }
}

/// Validate if a string is an email.
///
/// This checks if a string follows a simple pattern `_@_`.
pub fn is_email(error: e) {
  vcommon.custom(error, is_email_check)
}

fn min_length_check(min: Int) {
  fn(value: String) -> Option(String) {
    let len = string.length(value)

    case len < min {
      True -> None
      False -> Some(value)
    }
  }
}

/// Validate the min length of a string
pub fn min_length(error: e, min: Int) {
  vcommon.custom(error, min_length_check(min))
}

fn max_length_check(max: Int) {
  fn(value: String) -> Option(String) {
    let len = string.length(value)

    case len > max {
      True -> None
      False -> Some(value)
    }
  }
}

/// Validate the max length of a string
pub fn max_length(error: e, max: Int) {
  vcommon.custom(error, max_length_check(max))
}
