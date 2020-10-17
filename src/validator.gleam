import gleam/list
import gleam/result

pub fn validate(
		accumulator: Result(fn(b) -> next_accumulator, List(String)),
		value: a,
		validator: fn(a) -> Result(b, List(String))
	) -> Result(next_accumulator, List(String)) {

	case validator(value) {
		Ok(value) ->
			accumulator
				|> result.map(
					fn(acc) { acc(value) }
				)

		Error(errors) ->
			case accumulator {
				Ok(_) ->
					Error(errors)

				Error(previous_errors) ->
					Error(
						list.flatten([previous_errors, errors])
					)
			}

	}
}

pub fn keep(
		accumulator: Result(fn(value) -> next_accumulator, List(String)),
		value: value
	) -> Result(next_accumulator, List(String)) {

		case accumulator {
			Error(errors) ->
				Error(errors)
			Ok(acc) ->
				Ok(acc(value))
		}
}

pub fn custom_validator(
		error: error,
		check: fn(value) -> Bool
	) {

	fn(value: value) {
		case check(value) {
			True ->
				Ok(value)
			False ->
				Error([error])
		}
	}
}

pub fn map2(constructor: fn(a, b) -> value) {
	fn(a) {
		fn(b) {
				constructor(a, b)
		}
	}
}

pub fn map3(constructor: fn(a, b, c) -> value) {
	fn(a) {
		fn(b) {
			fn(c) {
				constructor(a, b, c)
			}
		}
	}
}

pub fn map4(constructor: fn(a, b, c, d) -> value) {
	fn(a) {
		fn(b) {
			fn(c) {
				fn(d) {
					constructor(a, b, c, d)
				}
			}
		}
	}
}

pub fn map5(constructor: fn(a, b, c, d, e) -> value) {
	fn(a) {
		fn(b) {
			fn(c) {
				fn(d) {
					fn(e) {
						constructor(a, b, c, d, e)
					}
				}
			}
		}
	}
}

pub fn map6(constructor: fn(a, b, c, d, e, f) -> value) {
	fn(a) {
		fn(b) {
			fn(c) {
				fn(d) {
					fn(e) {
						fn(f) {
								constructor(a, b, c, d, e, f)
						}
					}
				}
			}
		}
	}
}