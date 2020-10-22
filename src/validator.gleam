import gleam/list
import gleam/result
import validator/common.{Errors}

pub type ValidatorResult(a, e) =
	common.ValidatorResult(a, e)

fn curry2(constructor: fn(a, b) -> value) {
	fn(a) { fn(b) { constructor(a, b) } }
}

fn curry3(constructor: fn(a, b, c) -> value) {
	fn(a) { fn(b) { fn(c) { constructor(a, b, c) } } }
}

fn curry4(constructor: fn(a, b, c, d) -> value) {
	fn(a) { fn(b) { fn(c) { fn(d) { constructor(a, b, c, d) } } } }
}

fn curry5(constructor: fn(a, b, c, d, e) -> value) {
	fn(a) { fn(b) { fn(c) { fn(d) { fn(e) { constructor(a, b, c, d, e) } } } } }
}

fn curry6(constructor: fn(a, b, c, d, e, f) -> value) {
	fn(a) {
		fn(b) {
			fn(c) { fn(d) { fn(e) { fn(f) { constructor(a, b, c, d, e, f) } } } }
		}
	}
}

pub fn build1(constructor) {
	Ok(constructor)
}

pub fn build2(constructor) {
	Ok(curry2(constructor))
}

pub fn build3(constructor) {
	Ok(curry3(constructor))
}

pub fn build4(constructor) {
	Ok(curry4(constructor))
}

pub fn build5(constructor) {
	Ok(curry5(constructor))
}

pub fn build6(constructor) {
	Ok(curry6(constructor))
}

pub fn validate(
	accumulator: Result(fn(b) -> next_accumulator, Errors(e)),
	value: a,
	validator: fn(a) -> Result(b, Errors(e)),
) -> Result(next_accumulator, Errors(e)) {

	case validator(value) {
		Ok(value) ->
			accumulator
			|> result.map(fn(acc) { acc(value) })

		Error(tuple(e, errors)) ->
			case accumulator {
				Ok(_) ->
					Error(tuple(e, errors))

				Error(tuple(first_error, previous_errors)) ->
					Error(
						tuple(
							first_error,
							list.flatten([previous_errors, errors]),
						)
					)
			}
	}
}

pub fn keep(
	accumulator: Result(fn(value) -> next_accumulator, Errors(e)),
	value: value,
) -> Result(next_accumulator, Errors(e)) {

	case accumulator {
		Error(errors) ->
			Error(errors)
		Ok(acc) ->
			Ok(acc(value))
	}
}

pub fn custom(error, check) {
	common.custom(error, check)
}

/// Compose validators
/// Return the first one and if successful then the second
/// Only returns one error (because the validators may transform the type)
pub fn and(
		validator1: common.Validator(i, mid, e),
		validator2: common.Validator(mid, o, e)
	) -> common.Validator(i, o, e) {

		fn(input: i) {
			validator1(input)
				|> result.then(validator2)
		}
}

/// Chain validators
/// This runs all the validators in the list.
/// The initial input is passed to all validators.
/// All these validators must have the same input and output types.
/// Returns Ok when all validators pass.
/// Returns Error when any validator fails. Error will have all failures.
pub fn chain(
		validators: List(common.Validator(io, io, e))
	) -> common.Validator(io, io, e) {

	fn(input: io) -> Result(io, Errors(e)) {

		// let folder = fn(validator, acc) {
		// 	case validator(input) {
	
		// 		Error(tuple(e, errors)) ->
		// 			case acc {

		// 			}
		// 	}
		// 	acc
		// }

		// list.fold(
		// 	validators,
		// 	Ok(input),
		// 	folder
		// )
	}

}