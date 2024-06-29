import gleam/list
import gleam/result
import valid/vcommon.{type Errors, type ValidatorResult}

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

/// Build a validator for a type that has one attribute
///
/// ## Example
///
///	type Person { Person(name: String) }
///
///	let validator = fn(person: Person) {
///		v.build1(person)
///		|> v.validate(person.name, name_validator)
///	}
pub fn build1(constructor) {
  Ok(constructor)
}

/// Build a validator for a type that has two attributes
///
/// ## Example
///
///	type Person { Person(name: String, age: Int) }
///
///	let validator = fn(person: Person) {
///		v.build2(person)
///		|> v.validate(person.name, name_validator)
///		|> v.validate(person.age, ...)
///	}
pub fn build2(constructor) {
  Ok(curry2(constructor))
}

/// Build a validator for a type that has three attributes
///
/// ## Example
///
///	type Person { Person(name: String, age: Int, email: String) }
///
///	let validator = fn(person: Person) {
///		v.build3(person)
///		|> v.validate(person.name, name_validator)
///		|> v.validate(person.age, ...)
///		|> v.validate(person.email, ...)
///	}
pub fn build3(constructor) {
  Ok(curry3(constructor))
}

/// Build a validator for a type that has four attributes
pub fn build4(constructor) {
  Ok(curry4(constructor))
}

/// Build a validator for a type that has five attributes
pub fn build5(constructor) {
  Ok(curry5(constructor))
}

/// Build a validator for a type that has six attributes
pub fn build6(constructor) {
  Ok(curry6(constructor))
}

/// Validate an attribute.
///
/// ## Example
///
///	let validator = fn(person: Person) {
///		v.build1(Person)
///		|> v.validate(person.name, v_string.is_not_empty(ErrorEmpty))
///	}
///
pub fn validate(
  accumulator: Result(fn(b) -> next_accumulator, Errors(e)),
  value: a,
  validator: fn(a) -> Result(b, Errors(e)),
) -> Result(next_accumulator, Errors(e)) {
  case validator(value) {
    Ok(value) ->
      accumulator
      |> result.map(fn(acc) { acc(value) })

    Error(#(e, errors)) ->
      case accumulator {
        Ok(_) -> Error(#(e, errors))

        Error(#(first_error, previous_errors)) ->
          Error(#(first_error, list.flatten([previous_errors, errors])))
      }
  }
}

/// Keep a value as is.
///
/// ## Example
///
///	fn person_validor(person: Person) {
///		v.build2(Person)
///			|> v.validate(person.name, ...)
///			|> v.keep(person.age)
///	}
///
pub fn keep(
  accumulator: Result(fn(value) -> next_accumulator, Errors(e)),
  value: value,
) -> Result(next_accumulator, Errors(e)) {
  case accumulator {
    Error(errors) -> Error(errors)
    Ok(acc) -> Ok(acc(value))
  }
}

/// Create a custom validator
///
/// A custom validator has two attributes:
///
/// - The error
/// - A check function
///
/// The check function is a function that takes an `input` and returns `Option(output)`
///
/// ## Example
///
///	let must_be_sam = fn(name: String) -> Option(String) {
///		case name == "Sam" {
///			True -> Some(name)
///			False -> None
///		}
///	}
///
///	let validator = fn(person: Person) {
///		v.build1(Person)
///		|> v.validate(person.name, v.custom("Not Sam", must_be_sam))
///	}
pub fn custom(error, check) {
  vcommon.custom(error, check)
}

/// Compose validators
///
/// Run the first validator and if successful then the second.
/// Only returns the first error.
///
/// ## Example
///
///	let name_validator = v_string.is_not_empty("Empty")
///	|> v.and(v_string.min_length("Must be at least six", 6))
pub fn and(
  validator1: vcommon.Validator(i, mid, e),
  validator2: vcommon.Validator(mid, o, e),
) -> vcommon.Validator(i, o, e) {
  fn(input: i) {
    validator1(input)
    |> result.then(validator2)
  }
}

/// Validate a value using a list of validators.
/// This runs all the validators in the list.
///
/// The initial input is passed to all validators.
/// All these validators must have the same input and output types.
///
/// Returns Ok when all validators pass.
/// Returns Error when any validator fails. Error will have all failures.
///
/// ## Example
///
///	let name_validator = v.all([
///		v_string.is_not_empty("Empty"),
///		v_string.min_length(">=3", 3),
///		v_string.max_length("<=10", 10)
///	])
///
///	let validator = fn(person: Person) {
///		v.build1(person)
///		|> v.validate(person.name, name_validator)
///	}
pub fn all(
  validators: List(vcommon.Validator(io, io, e)),
) -> vcommon.Validator(io, io, e) {
  fn(input: io) -> Result(io, Errors(e)) {
    let results =
      validators
      |> list.map(fn(validator) { validator(input) })

    let errors =
      results
      |> list.map(fn(result) {
        case result {
          Ok(_) -> []
          Error(#(_first, rest)) -> rest
        }
      })
      |> list.flatten

    case list.first(errors) {
      Error(Nil) -> Ok(input)
      Ok(head) -> Error(#(head, errors))
    }
  }
}

/// Validate a structure as a whole.
///
/// Sometimes we need to validate a property in relation to another.
///
/// This function requires a check function like:
///
///	fn(a) -> Result(a, error)
///
/// ## Example
///
///	let strengh_and_level_validator = fn(c: Character) {
///		case c.level > c.strength {
///			True -> Error(error)
///			False -> Ok(c)
///		}
///	}
///
///	let validator = fn(c: Character) {
///		v.build2(Character)
///		|> v.validate(c.level, v_int.min("Level must be more that zero", 1))
///		|> v.validate(c.strength, v_int.min("Strength must be more that zero", 1))
///		|> v.whole(strengh_and_level_validator)
///	}
///
pub fn whole(validator: fn(whole) -> Result(whole, error)) {
  fn(validation_result: ValidatorResult(whole, error)) {
    validation_result
    |> result.then(fn(validated: whole) {
      validator(validated)
      |> result.map_error(fn(error) { #(error, [error]) })
    })
  }
}
