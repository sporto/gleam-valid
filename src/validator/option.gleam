import gleam/option.{None, Option, Some}
import validator/common.{Validator}

fn is_some_check(
		maybe: Option(value),
	) -> Option(value) {

	case maybe {
		None -> None
		Some(value) -> Some(value)
	}
}

pub fn is_some(error: e) -> Validator(Option(i),i,e) {
	common.custom(error, is_some_check)
}

/// Validate an optional value
/// Run the validator only if the value is Some
/// If None returns Ok(None)
pub fn optional(
		validator: Validator(input, input, error)
	) {

	fn(maybe: Option(input)) {
		case maybe {
			None ->
				Ok(maybe)

			Some(value) ->
				case validator(value) {
					Ok(_) -> Ok(maybe)
					Error(error) -> Error(error)
				}
		}
	}
}
