import gleam/string

pub fn is_not_empty(error: e) {
  fn(value: String) {
    case string.is_empty(value) {
      True -> Error([error])
      False -> Ok(value)
    }
  }
}

pub fn min_length(error: e, min: Int) {
  fn(value: String) {
    let len = string.length(value)
    case len < min {
      True -> Error([error])
      False -> Ok(value)
    }
  }
}

pub fn max_length(error: e, max: Int) {
  fn(value: String) {
    let len = string.length(value)
    case len > max {
      True -> Error([error])
      False -> Ok(value)
    }
  }
}