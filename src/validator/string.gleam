import gleam/option.{None, Option, Some}
import gleam/string
import validator/common

pub fn is_not_empty(error: e) {
  let check = fn(value: String) -> Result(String, e) {
    case string.is_empty(value) {
      True -> Error(error)
      False -> Ok(value)
    }
  }

  common.custom_validator(check)
}

pub fn min_length(error: e, min: Int) {
  let check = fn(value: String) -> Result(String, e) {
    let len = string.length(value)
    case len < min {
      True -> Error(error)
      False -> Ok(value)
    }
  }

  common.custom_validator(check)
}

pub fn max_length(error: e, max: Int) {
  let check = fn(value: String) -> Result(String, e) {
    let len = string.length(value)
    case len > max {
      True -> Error(error)
      False -> Ok(value)
    }
  }

  common.custom_validator(check)
}
