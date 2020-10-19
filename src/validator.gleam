import gleam/list
import gleam/result
import validator/common

pub fn validate(
	accumulator: Result(fn(b) -> next_accumulator, List(e)),
	value: a,
	validator: fn(a) -> Result(b, List(e)),
) -> Result(next_accumulator, List(e)) {
	case validator(value) {
		Ok(value) ->
			accumulator
			|> result.map(fn(acc) { acc(value) })

		Error(errors) ->
			case accumulator {
				Ok(_) -> Error(errors)
				Error(previous_errors) -> Error(list.flatten([previous_errors, errors]))
			}
	}
}

pub fn keep(
	accumulator: Result(fn(value) -> next_accumulator, List(e)),
	value: value,
) -> Result(next_accumulator, List(e)) {
	case accumulator {
		Error(errors) -> Error(errors)
		Ok(acc) -> Ok(acc(value))
	}
}

pub fn custom_validator(error, check) {
	common.custom_validator(error, check)
}

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
