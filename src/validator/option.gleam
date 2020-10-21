import gleam/option.{None, Option, Some}
import validator/common

fn is_some_check(
		maybe: Option(value),
	) -> Option(value) {

	case maybe {
		None -> None
		Some(value) -> Some(value)
	}
}

pub fn is_some(error: e) {
	common.custom(error, is_some_check)
}
