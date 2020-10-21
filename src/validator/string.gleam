import gleam/option.{None, Option, Some}
import gleam/string
import validator/common

fn is_not_empty_check(value: String) -> Option(String) {

	case string.is_empty(value) {
		True ->
			None

		False ->
			Some(value)
	}
}

pub fn is_not_empty(error: e) {
	common.custom(error, is_not_empty_check)
}

fn min_length_check(min: Int) {
	fn(value: String) -> Option(String) {
		let len = string.length(value)

		case len < min {
			True ->
				None

			False ->
				Some(value)
		}
	}
}

pub fn min_length(error: e, min: Int) {
	common.custom(error, min_length_check(min))
}

fn max_length_check(max: Int) {
	fn(value: String) -> Option(String) {
		let len = string.length(value)

		case len > max {
			True ->
				None

			False ->
				Some(value)
		}
	}
}

pub fn max_length(error: e, max: Int) {
	common.custom(error, max_length_check(max))
}
