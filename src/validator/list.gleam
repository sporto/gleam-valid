import validator/common.{Validator}
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

pub fn is_not_empty(error: error) {
	common.custom(error, is_not_empty_check)
}

fn min_length_check(min: Int) {
	fn(value: List(a)) -> Option(List(a)) {

		case list.length(value) < min {
			True ->
				None

			False ->
				Some(value)
		}
	}
}

pub fn min_length(error: error, min: Int) {
	common.custom(error, min_length_check(min))
}

fn max_length_check(max: Int) {
	fn(value: List(a)) -> Option(List(a)) {

		case list.length(value) > max {
			True ->
				None

			False ->
				Some(value)
		}
	}
}

pub fn max_length(error: error, max: Int) {
	common.custom(error, max_length_check(max))
}

/// Validate a list of items.
/// Run the given validator for each item.
/// Returns all the errors.
pub fn every(
		validator: Validator(input, output, error)
	) {

	fn(items: List(input)) {
		let results = items
		|> list.map(validator)

		let errors = results
			|> list.map(fn(result) {
				case result {
					Ok(_) -> []
					Error(tuple(first, rest)) -> rest
				}
			})
			|> list.flatten

		case list.head(errors) {
			Error(Nil) ->
				Ok(items)
			Ok(head) ->
				Error(tuple(head, errors))
		}
	}
}