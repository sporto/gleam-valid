import gleam/option.{None, Option, Some}
import validator/common

fn min_check(min: Int) {
	fn(value: Int) -> Option(Int) {
		case value < min {
			True ->
				None

			False ->
				Some(value)
		}
	}
}

pub fn min(error: e, min: Int) {
	common.custom(error, min_check(min))
}

fn max_check(max: Int) {
	fn(value: Int) -> Option(Int) {
		case value > max {
			True ->
				None

			False ->
				Some(value)
		}
	}
}

pub fn max(error: e, max: Int) {
	common.custom(error, max_check(max))
}