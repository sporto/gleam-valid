import gleam/option.{None, Option, Some}

pub type Errors(e) =
	tuple(e, List(e))

pub type ValidatorResult(a, e) =
	Result(a, Errors(e))

pub type Validator(input, output, e) =
	fn(input) -> Result(output, Errors(e))

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
