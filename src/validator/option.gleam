import gleam/option.{type Option, None, Some}
import validator/common.{type Validator}

fn is_some_check(maybe: Option(value)) -> Option(value) {
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
///		v.build1(PersonValid)
///		|> v.validate(person.name, option.is_some("Name is null"))
///	}
///
pub fn is_some(error: e) -> Validator(Option(i), i, e) {
  common.custom(error, is_some_check)
}

/// Validate an optional value.
///
/// Run the validator only if the value is Some.
/// If the value is None then just return None back.
///
/// ## Example
///
///	let validator = fn(person) {
///		v.build1(PersonValid)
///		|> v.validate(
///			person.name,
///			option.optional(string.min_length("Short", 3))
///		)
///	}
///
pub fn optional(validator: Validator(input, input, error)) {
  fn(maybe: Option(input)) {
    case maybe {
      None -> Ok(maybe)

      Some(value) ->
        case validator(value) {
          Ok(_) -> Ok(maybe)
          Error(error) -> Error(error)
        }
    }
  }
}
