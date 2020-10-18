pub fn custom_validator(check: fn(input) -> Result(output, error)) {
  fn(input: input) {
    case check(input) {
      Ok(output) -> Ok(output)
      Error(error) -> Error([error])
    }
  }
}
