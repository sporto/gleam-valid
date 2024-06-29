import gleam/option.{type Option, None, Some}

/// Error type returned by the validator.
///
/// This is a # with the first error and a list of all errors.
/// The list includes the first error.
pub type Errors(error) =
  #(error, List(error))

pub type ValidatorResult(output, error) =
  Result(output, Errors(error))

/// A Validator is a function that takes an input and
/// returns a ValidatorResult
pub type Validator(input, output, error) =
  fn(input) -> ValidatorResult(output, error)

/// Create a custom validator, see documentation in root module
pub fn custom(
  error: e,
  check: fn(input) -> Option(output),
) -> Validator(input, output, e) {
  fn(input: input) -> Result(output, Errors(e)) {
    case check(input) {
      Some(output) -> Ok(output)

      None -> Error(#(error, [error]))
    }
  }
}
