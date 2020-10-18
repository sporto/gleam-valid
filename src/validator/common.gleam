import gleam/option.{None, Option, Some}

pub fn custom_validator(
		error: e,
		check: fn(input) -> Option(output)
	) {

	fn(input: input) {
		case check(input) {
			Some(output) ->
				Ok(output)

			None ->
				Error([error])
		}
	}
}
