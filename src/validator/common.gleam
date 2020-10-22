import gleam/option.{None, Option, Some}

pub type Errors(error) =
	tuple(error, List(error))

pub type ValidatorResult(output, error) =
	Result(output, Errors(error))

/// A Validator is a function that takes an input and
/// returns a ValidatorResult
pub type Validator(input, output, error) =
	fn(input) -> ValidatorResult(output, error)

pub fn custom(
		error: e,
		check: fn(input) -> Option(output)
	) -> Validator(input, output, e) {

	fn(input: input) -> Result(output, Errors(e)) {
		case check(input) {
			Some(output) ->
				Ok(output)

			None ->
				Error(tuple(error, [error]))
		}
	}
}
