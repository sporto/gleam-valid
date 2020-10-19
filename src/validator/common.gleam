import gleam/option.{None, Option, Some}

pub type Errors(e) =
	tuple(e, List(e))

pub type ValidatorResult(a, e) =
	Result(a, Errors(e))

pub fn custom_validator(
		error: e,
		check: fn(input) -> Option(output)
	) {

	fn(input: input) -> Result(output, Errors(e)) {
		case check(input) {
			Some(output) ->
				Ok(output)

			None ->
				Error(tuple(error, [error]))
		}
	}
}
