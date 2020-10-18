import gleam/option.{None, Option, Some}
import gleam/string
import validator/common

pub fn is_not_empty(error: e) {
  let check = fn(value: String) -> Option(String) {
    case string.is_empty(value) {
      True -> None
      False -> Some(value)
    }
  }

  common.custom_validator(error, check)
}

pub fn min_length(error: e, min: Int) {
  let check = fn(value: String) -> Option(String) {
    let len = string.length(value)
    case len < min {
      True -> None
      False -> Some(value)
    }
  }

  common.custom_validator(error, check)
}

pub fn max_length(error: e, max: Int) {
  let check = fn(value: String) -> Option(String) {
    let len = string.length(value)
    case len > max {
      True -> None
      False -> Some(value)
    }
  }

  common.custom_validator(error, check)
}
