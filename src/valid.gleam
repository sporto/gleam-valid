import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string

/// A non empty list.
/// Errors returned by a validator are returned in this format.
pub type NonEmptyList(a) {
  NonEmptyList(first: a, rest: List(a))
}

pub type Check(input, output, error) =
  fn(input) -> Result(output, error)

pub type ValidatorResult(output, error) =
  Result(output, NonEmptyList(error))

/// A Validator is a function that takes an input and
/// returns a ValidatorResult
pub type Validator(input, output, error) =
  fn(input) -> ValidatorResult(output, error)

/// Internal Utility
///
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

// Add errors to result
// If result was ok then it becomes Err(errors)
// If result already has errors, then append new errors
fn add_errors(
  result: Result(a, NonEmptyList(e)),
  errors: NonEmptyList(e),
) -> Result(b, NonEmptyList(e)) {
  case result {
    Ok(_) -> Error(errors)
    Error(existing_errors) -> {
      let next_errors = non_empty_append(existing_errors, errors)
      Error(next_errors)
    }
  }
}

// Change a single error to a list of errors
fn error_to_errors(error: e) -> NonEmptyList(e) {
  non_empty_new(error, [])
}

/// Construct a NonEmptyList
pub fn non_empty_new(first: a, rest: List(a)) -> NonEmptyList(a) {
  NonEmptyList(first, rest)
}

fn non_empty_append(
  first: NonEmptyList(a),
  second: NonEmptyList(a),
) -> NonEmptyList(a) {
  non_empty_new(first.first, list.append(first.rest, non_empty_to_list(second)))
}

/// Transform NonEmptyList into a List
pub fn non_empty_to_list(non_empty: NonEmptyList(a)) -> List(a) {
  [non_empty.first, ..non_empty.rest]
}

/// Build a validator for a type that has one attribute
///
/// ## Example
///
///	type Person { Person(name: String) }
///
///	let validator = fn(person: Person) {
///		valid.build1(person)
///		|> valid.check(person.name, name_validator)
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
///		valid.build2(person)
///		|> valid.check(person.name, name_validator)
///		|> valid.check(person.age, ...)
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
///		valid.build3(person)
///		|> valid.check(person.name, name_validator)
///		|> valid.check(person.age, ...)
///		|> valid.check(person.email, ...)
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
///		valid.build1(Person)
///		|> valid.check(person.name, valid.string_is_not_empty(ErrorEmpty))
///	}
///
pub fn check(
  accumulator: Result(fn(out) -> next_constructor, NonEmptyList(e)),
  input: in,
  validator: Validator(in, out, e),
) -> Result(next_constructor, NonEmptyList(e)) {
  case validator(input) {
    Ok(out) ->
      accumulator
      |> result.map(fn(acc) { acc(out) })

    Error(errors) -> add_errors(accumulator, errors)
  }
}

/// Validate an attribute required in a dictionary
/// If you have a dictionary instead of a custom type, use this.
///
/// ## Example
///
///	let validator = fn(dictionary: Dict(String, String)) {
///		valid.build1(Person)
///		|> valid.check_required_in_dict(
///     from: dictionary,
///     get: "name",
///     missing: "Missing name",
///     validator: valid.string_is_not_empty(ErrorEmpty)
///   )
///	}
///
pub fn required_in_dict(key: String, error: e) {
  let fun = fn(dictionary) {
    dict.get(dictionary, key)
    |> option.from_result
  }
  required_in(fun, error)
}

/// Validate an attribute required in an arbitrary data type
/// Here you provide your own accessor
/// The accessor should return `Option(property)`
///
/// ## Example
///
/// let get_name = fn(d) { dict.get(d, "name") |> option.from_result }
///
///	let validator = fn(dictionary: Dict(String, String)) {
///		valid.build1(Person)
///		|> valid.check(
///     dictionary,
///     required_in(get_name, "Missing name")
///       |> valid.and(
///         valid.string_is_not_empty(ErrorEmpty)
///       )
///   )
///	}
///
pub fn required_in(get: fn(a) -> Option(b), error: e) -> Validator(a, b, e) {
  fn(input: a) {
    case get(input) {
      None -> Error(non_empty_new(error, []))
      Some(a) -> Ok(a)
    }
  }
}

pub fn optional_in_dict(key: String) {
  let fun = fn(dictionary) {
    dict.get(dictionary, key)
    |> option.from_result
  }
  optional_in(fun)
}

pub fn optional_in(get: fn(input) -> Option(a)) {
  fn(input: input) {
    case get(input) {
      Some(a) -> Ok(Some(a))
      None -> Ok(None)
    }
  }
}

// TODO simplify
///
/// Keep a value as is.
///
/// ## Example
///
///	fn person_validor(person: Person) {
///		valid.build2(Person)
///			|> valid.check(person.name, ...)
///			|> valid.keep(person.age)
///	}
///
pub fn keep(
  accumulator: Result(fn(value) -> next_accumulator, NonEmptyList(e)),
  value: value,
) -> Result(next_accumulator, NonEmptyList(e)) {
  check(accumulator, value, ok())
}

/// A validator that always succeeds
pub fn ok() -> Validator(io, io, e) {
  Ok
}

/// Compose validators
///
/// Run the first validator and if successful then the second.
/// Only returns the first error.
///
/// ## Example
///
///	let name_validator = valid.string_is_not_empty("Empty")
///	|> valid.and(valid.string_min_length("Must be at least six", 6))
pub fn and(
  validator1: Validator(i, mid, e),
  validator2: Validator(mid, o, e),
) -> Validator(i, o, e) {
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
///	let name_validator = valid.all([
///		valid.string_is_not_empty("Empty"),
///		valid.string_min_length(">=3", 3),
///		valid.string_max_length("<=10", 10)
///	])
///
///	let validator = fn(person: Person) {
///		valid.build1(person)
///		|> valid.check(person.name, name_validator)
///	}
pub fn all(validators: List(Validator(in, in, e))) -> Validator(in, in, e) {
  fn(input: in) -> ValidatorResult(in, e) {
    list.fold(over: validators, from: Ok(input), with: fn(acc, validator) {
      let res = validator(input)

      case res {
        Ok(_) -> acc
        Error(errors) -> add_errors(acc, errors)
      }
    })
  }
}

/// Validate a resulting type as a whole.
///
/// Sometimes we need to validate a property in relation to another.
/// This validator must be at the end of the pipeline.
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
///		valid.build2(Character)
///		|> valid.check(c.level, valid.int_min("Level must be more that zero", 1))
///		|> valid.check(c.strength, valid.int_min("Strength must be more that zero", 1))
///		|> valid.whole(c, strengh_and_level_validator)
///	}
///
pub fn whole(
  accumulator: Result(in, NonEmptyList(e)),
  validator: Validator(in, out, e),
) {
  result.then(accumulator, fn(input: in) {
    case validator(input) {
      Ok(out) -> Ok(out)
      Error(errors) -> add_errors(accumulator, errors)
    }
  })
}

// TODO test
pub fn check_only(
  accumulator: Result(fn(out) -> next_accumulator, NonEmptyList(e)),
  input: in,
  validator: Validator(in, in, e),
) {
  // Run the validator, but discard the Ok result
  case validator(input) {
    Ok(_) -> accumulator
    Error(errors) -> add_errors(accumulator, errors)
  }
}

/// Integer checks
pub fn int_min(min: Int, error: e) -> Validator(Int, Int, e) {
  fn(value: Int) {
    case value < min {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

pub fn int_max(max: Int, error: e) -> Validator(Int, Int, e) {
  fn(value: Int) {
    case value > max {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

/// String checks
///
/// Validate that a string is not empty
pub fn string_is_not_empty(error: e) -> Validator(String, String, e) {
  fn(value: String) {
    case string.is_empty(value) {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

/// Validate if a string parses to an Int. Returns the Int if so.
pub fn string_is_int(error: e) -> Validator(String, Int, e) {
  fn(value: String) {
    int.parse(value)
    |> result.replace_error(non_empty_new(error, []))
  }
}

/// Validate if a string parses to an Float. Returns the Float if so.
pub fn string_is_float(error: e) -> Validator(String, Float, e) {
  fn(value: String) {
    float.parse(value)
    |> result.replace_error(non_empty_new(error, []))
  }
}

/// Validate if a string is an email.
///
/// This checks if a string follows a simple pattern `_@_`.
pub fn string_is_email(error: e) -> Validator(String, String, e) {
  fn(value: String) {
    let errors = non_empty_new(error, [])
    let pattern = "^[\\w\\d]+@[\\w\\d\\.]+$"

    case regex.from_string(pattern) {
      Ok(re) -> {
        case regex.check(with: re, content: value) {
          True -> Ok(value)
          False -> Error(errors)
        }
      }
      Error(_) -> Error(errors)
    }
  }
}

/// Validate the min length of a string
pub fn string_min_length(min: Int, error: e) -> Validator(String, String, e) {
  fn(value: String) {
    let len = string.length(value)

    case len < min {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

/// Validate the max length of a string
pub fn string_max_length(max: Int, error: e) -> Validator(String, String, e) {
  fn(value: String) {
    let len = string.length(value)

    case len > max {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

/// List checks
///
/// Validate that a list is not empty
pub fn list_is_not_empty(error: e) -> Validator(List(a), List(a), e) {
  fn(value: List(a)) {
    case list.is_empty(value) {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

/// Validate the min number of items in a list
pub fn list_min_length(min: Int, error: e) -> Validator(List(a), List(a), e) {
  fn(value: List(a)) {
    case list.length(value) < min {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

/// Validate the max number of items in a list
pub fn list_max_length(max: Int, error: e) -> Validator(List(a), List(a), e) {
  fn(value: List(a)) {
    case list.length(value) > max {
      True -> Error(non_empty_new(error, []))
      False -> Ok(value)
    }
  }
}

/// Validate a list of items.
///
/// Run the given validator for each item returning all the errors.
///
/// ## Example
///
///	type Collection = { Collection(items: List(String) ) }
///
///	let list_validator = valid.list_every(
///		valid.string_min_length("Must be at least 3", 3)
///	)
///
///	let validator = fn(collection: Collection) {
///		valid.build1(Collection)
///		|> valid.check(collection.items, list_validator)
///	}
pub fn list_every(validator: Validator(input, output, error)) {
  fn(inputs: List(input)) {
    list.fold(over: inputs, from: Ok([]), with: fn(acc, input) {
      case validator(input) {
        Ok(out) -> result.map(acc, fn(outs) { list.append(outs, [out]) })
        Error(errors) -> add_errors(acc, errors)
      }
    })
  }
}

/// Option checks
///
/// Validate that a value is not None.
/// Returns the value if Some.
///
/// ## Example
///
///	type PersonInput { PersonInput(name: Option(String)) }
///
///	type PersonValid { PersonValid(name: String) }
///
///	let validator = fn(person) {
///		valid.build1(PersonValid)
///		|> valid.check(person.name, valid.is_some("Name is null"))
///	}
///
pub fn is_some(error: e) -> Validator(Option(a), a, e) {
  fn(option: Option(a)) {
    case option {
      None -> Error(non_empty_new(error, []))
      Some(value) -> Ok(value)
    }
  }
}

/// Validate an optional value.
///
/// Run the validator only if the value is Some.
/// If the value is None then return None back.
///
/// ## Example
///
/// type PersonValid{
///   PersonValid(name: Option(String))
/// }
///
///	let validator = fn(person) {
///		valid.build1(PersonValid)
///		|> valid.check(
///			person.name,
///			valid.optional(valid.string_min_length("Short", 3))
///		)
///	}
///
pub fn optional(
  validator: Validator(a, b, error),
) -> Validator(Option(a), Option(b), error) {
  fn(maybe_a: Option(a)) {
    case maybe_a {
      None -> Ok(None)

      Some(a) -> {
        case validator(a) {
          Ok(b) -> Ok(Some(b))
          Error(error) -> Error(error)
        }
      }
    }
  }
}
