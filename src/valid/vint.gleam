import gleam/option.{type Option, None, Some}
import valid/vcommon

fn min_check(min: Int) {
  fn(value: Int) -> Option(Int) {
    case value < min {
      True -> None

      False -> Some(value)
    }
  }
}

pub fn min(error: e, min: Int) {
  vcommon.custom(error, min_check(min))
}

fn max_check(max: Int) {
  fn(value: Int) -> Option(Int) {
    case value > max {
      True -> None

      False -> Some(value)
    }
  }
}

pub fn max(error: e, max: Int) {
  vcommon.custom(error, max_check(max))
}
