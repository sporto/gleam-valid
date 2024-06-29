import gleam/dict.{type Dict}
import gleam/float
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string

/// Error type returned by the validator.
///
/// This is a # with the first error and a list of all errors.
/// The list includes the first error.
pub type Errors(error) =
  #(error, List(error))

pub type ValidatorResult(output, error) =
  Result(output, Errors(error))

/// A Validator is a function that takes an input and
/// returns a ValidatorResult
pub type Validator(input, output, error) =
  fn(input) -> ValidatorResult(output, error)

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
///		|> valid.check_required(
///     from: dictionary,
///     get: get_name,
///     missing: "Missing name",
///     validator: valid.string_is_not_empty(ErrorEmpty)
///   )
///	}
///
pub fn required_in(get: fn(input) -> Option(a), error: e) {
  custom(error, fn(input) { get(input) })
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
  accumulator: Result(fn(value) -> next_accumulator, Errors(e)),
  value: value,
) -> Result(next_accumulator, Errors(e)) {
  check(accumulator, value, ok())
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
///		valid.build1(Person)
///		|> valid.check(person.name, valid.custom("Not Sam", must_be_sam))
///	}
pub fn custom(
  error: e,
  assert_: fn(input) -> Option(output),
) -> Validator(input, output, e) {
  fn(input: input) -> Result(output, Errors(e)) {
    case assert_(input) {
      Some(output) -> Ok(output)

      None -> Error(#(error, [error]))
    }
  }
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

fn with_and(validator) {
  fn(first) { and(first, validator) }
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
pub fn all(validators: List(Validator(io, io, e))) -> Validator(io, io, e) {
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
///		valid.build2(Character)
///		|> valid.check(c.level, valid.int_min("Level must be more that zero", 1))
///		|> valid.check(c.strength, valid.int_min("Strength must be more that zero", 1))
///		|> valid.whole(strengh_and_level_validator)
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

/// Integer checks
fn int_min_assert(min: Int) {
  fn(value: Int) -> Option(Int) {
    case value < min {
      True -> None

      False -> Some(value)
    }
  }
}

pub fn int_min(error: e, min: Int) {
  custom(error, int_min_assert(min))
}

pub fn and_int_min(error: e, min: Int) {
  int_min(error, min)
  |> with_and
}

fn int_max_assert(max: Int) {
  fn(value: Int) -> Option(Int) {
    case value > max {
      True -> None

      False -> Some(value)
    }
  }
}

pub fn int_max(error: e, max: Int) {
  custom(error, int_max_assert(max))
}

/// String checks
fn string_is_not_empty_assert(value: String) -> Option(String) {
  case string.is_empty(value) {
    True -> None

    False -> Some(value)
  }
}

/// Validate if a string is not empty
pub fn string_is_not_empty(error: e) {
  custom(error, string_is_not_empty_assert)
}

pub fn and_string_is_not_empty(error: e) {
  string_is_not_empty(error)
  |> with_and
}

/// Validate if a string parses to an Int. Returns the Int if so.
pub fn string_is_int(error: e) {
  custom(error, fn(value) {
    int.parse(value)
    |> option.from_result
  })
}

pub fn and_string_is_int(error: e) {
  string_is_int(error)
  |> with_and
}

/// Validate if a string parses to an Float. Returns the Float if so.
pub fn string_is_float(error: e) {
  custom(error, fn(value) {
    float.parse(value)
    |> option.from_result
  })
}

fn string_is_email_assert(value: String) -> Option(String) {
  let pattern = "^[\\w\\d]+@[\\w\\d\\.]+$"

  case regex.from_string(pattern) {
    Ok(re) -> {
      case regex.check(with: re, content: value) {
        True -> Some(value)

        False -> None
      }
    }
    Error(_) -> None
  }
}

/// Validate if a string is an email.
///
/// This checks if a string follows a simple pattern `_@_`.
pub fn string_is_email(error: e) {
  custom(error, string_is_email_assert)
}

pub fn and_string_is_email(error: e) {
  string_is_email(error)
  |> with_and
}

fn string_min_length_assert(min: Int) {
  fn(value: String) -> Option(String) {
    let len = string.length(value)

    case len < min {
      True -> None
      False -> Some(value)
    }
  }
}

/// Validate the min length of a string
pub fn string_min_length(error: e, min: Int) {
  custom(error, string_min_length_assert(min))
}

pub fn and_string_min_length(error: e, min: Int) {
  string_min_length(error, min)
  |> with_and
}

fn string_max_length_assert(max: Int) {
  fn(value: String) -> Option(String) {
    let len = string.length(value)

    case len > max {
      True -> None
      False -> Some(value)
    }
  }
}

/// Validate the max length of a string
pub fn string_max_length(error: e, max: Int) {
  custom(error, string_max_length_assert(max))
}

pub fn and_string_max_length(error: e, max: Int) {
  string_max_length(error, max)
  |> with_and
}

/// List checks
///
fn list_is_not_empty_assert(value: List(a)) -> Option(List(a)) {
  case list.is_empty(value) {
    True -> None

    False -> Some(value)
  }
}

/// Validate that a list is not empty
pub fn list_is_not_empty(error: e) {
  custom(error, list_is_not_empty_assert)
}

pub fn and_list_is_not_empty(error: e) {
  list_is_not_empty(error)
  |> with_and
}

fn list_min_length_assert(min: Int) {
  fn(value: List(a)) -> Option(List(a)) {
    case list.length(value) < min {
      True -> None

      False -> Some(value)
    }
  }
}

/// Validate the min number of items in a list
pub fn list_min_length(error: e, min: Int) {
  custom(error, list_min_length_assert(min))
}

pub fn and_list_min_length(error: e, min: Int) {
  list_min_length(error, min)
  |> with_and
}

fn list_max_length_assert(max: Int) {
  fn(value: List(a)) -> Option(List(a)) {
    case list.length(value) > max {
      True -> None

      False -> Some(value)
    }
  }
}

/// Validate the max number of items in a list
pub fn list_max_length(error: e, max: Int) {
  custom(error, list_max_length_assert(max))
}

pub fn and_list_max_length(error: e, max: Int) {
  list_max_length(error, max)
  |> with_and
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
  fn(items: List(input)) {
    let results =
      items
      |> list.map(validator)

    let errors =
      results
      |> list.map(fn(result) {
        case result {
          Ok(_) -> []
          Error(#(_first, rest)) -> rest
        }
      })
      |> list.flatten

    let ok_items =
      results
      |> list.filter_map(function.identity)

    case list.first(errors) {
      Error(Nil) -> Ok(ok_items)
      Ok(head) -> Error(#(head, errors))
    }
  }
}

/// Option checks
///
fn is_some_assert(maybe: Option(value)) -> Option(value) {
  case maybe {
    None -> None
    Some(value) -> Some(value)
  }
}

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
pub fn is_some(error: e) -> Validator(Option(i), i, e) {
  custom(error, is_some_assert)
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

pub fn and_optional(validator: Validator(a, b, error)) {
  optional(validator)
  |> with_and
}
