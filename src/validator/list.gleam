import validator/common
import gleam/list
import gleam/option.{None, Option, Some}

fn is_not_empty_check(value: List(a)) -> Option(List(a)) {

	case list.is_empty(value) {
		True ->
			None

		False ->
			Some(value)
	}
}

pub fn is_not_empty(error: e) {
	common.custom(error, is_not_empty_check)
}