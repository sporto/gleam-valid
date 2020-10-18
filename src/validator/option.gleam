import gleam/option.{None, Option, Some}
import validator/common

pub fn is_some(error: e) {
	let check = fn(maybe: Option(value)) -> Result(value, e) {
		case maybe {
			None -> Error(error)
			Some(value) -> Ok(value)
		}
	}
	common.custom_validator(check)
}
