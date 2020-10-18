import gleam/option.{None, Option, Some}

pub fn custom_validator(error: error, check: fn(input) -> Option(output)) {
  fn(input: input) {
    case check(input) {
      Some(output) -> Ok(output)
      None -> Error([error])
    }
  }
}
