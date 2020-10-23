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

/// Validate that a list is not empty
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

/// Validate the min number of items in a list
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

/// Validate the max number of items in a list
pub fn max_length(error: error, max: Int) {
	common.custom(error, max_length_check(max))
}

/// Validate a list of items.
///
/// Run the given validator for each item returning all the errors.
///
/// ## Example
///
///	type Collection = { Collection(items: List(String) ) }
///
///	let list_validator = v_list.every(
///		v_string.min_length("Must be at least 3", 3)
///	)
///
///	let validator = fn(collection: Collection) {
///		v.build1(Collection)
///		|> v.validate(collection.items, list_validator)
///	}

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