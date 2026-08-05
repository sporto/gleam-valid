import gleam/function
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import valid

pub fn main() {
  gleeunit.main()
}

pub type InputUser {
  InputUser(age: Int, name: String, email: String)
}

pub type ValidUser {
  ValidUser(age: Int, name: String, email: String)
}

pub type Status {
  Active
}

pub fn status_from_code(code: String) {
  case code {
    "Active" -> Ok(Active)
    _ -> Error("Invalid " <> code)
  }
}

fn user_validator(input: InputUser) {
  use age <- valid.check(input.age, valid.int_min(13, "Age"))
  use name <- valid.check(input.name, valid.string_is_not_empty("Name"))
  use email <- valid.check(input.email, valid.string_is_email("Email"))

  valid.ok(ValidUser(age:, name:, email:))
}

pub fn valid_test() {
  let input = InputUser(age: 14, name: "Sam", email: "sam@sample.com")

  input
  |> valid.validate(user_validator)
  |> should.equal(Ok(ValidUser(14, "Sam", "sam@sample.com")))
}

pub fn invalid_test() {
  let input = InputUser(age: 12, name: "", email: "sample.com")

  input
  |> valid.validate(user_validator)
  |> should.equal(Error(["Age", "Name", "Email"]))
}

pub fn all_test() {
  let string_contains = fn(wanted) {
    fn(input) {
      case string.contains(input, wanted) {
        True -> #(input, [])
        False -> #("", [wanted])
      }
    }
  }

  let validator = fn(input: String) {
    use out <- valid.check(
      input,
      valid.all([string_contains("$"), string_contains("*")]),
    )
    valid.ok(out)
  }

  "*$"
  |> valid.validate(validator)
  |> should.equal(Ok("*$"))

  "*"
  |> valid.validate(validator)
  |> should.equal(Error(["$"]))

  "Hello"
  |> valid.validate(validator)
  |> should.equal(Error(["$", "*"]))
}

pub fn custom_validator_test() {
  let custom_validator = fn(input) {
    case input == "Hola" {
      True -> #(input, [])
      False -> #("", ["Not Hola"])
    }
  }

  let validator = fn(input) {
    use out <- valid.check(input, custom_validator)

    valid.ok(out)
  }

  "Hola"
  |> valid.validate(validator)
  |> should.equal(Ok("Hola"))
}

pub fn is_some_valid_test() {
  let validator = fn(input) {
    use validated <- valid.check(input, valid.is_some("", valid.ok, "Input"))
    valid.ok(validated)
  }

  None
  |> valid.validate(validator)
  |> should.equal(Error(["Input"]))

  Some("Sally")
  |> valid.validate(validator)
  |> should.equal(Ok("Sally"))
}

pub fn is_some_and_transform_test() {
  let validator = fn(input) {
    use validated <- valid.check(
      input,
      valid.is_some(0, valid.string_is_int("Not Int"), "Input"),
    )
    valid.ok(validated)
  }

  None
  |> valid.validate(validator)
  |> should.equal(Error(["Input"]))

  Some("1")
  |> valid.validate(validator)
  |> should.equal(Ok(1))

  Some("Sally")
  |> valid.validate(validator)
  |> should.equal(Error(["Not Int"]))
}

pub fn list_all_test() {
  let validator = fn(input) {
    use items <- valid.check(
      input,
      valid.list_all(valid.string_is_not_empty("Empty")),
    )
    valid.ok(items)
  }

  ["Sam", ""]
  |> valid.validate(validator)
  |> should.equal(Error(["Empty"]))

  ["Sam", "Sally"]
  |> valid.validate(validator)
  |> should.equal(Ok(["Sam", "Sally"]))
}

pub fn optional_test() {
  let validator = fn(input) {
    use out <- valid.check(
      input,
      valid.optional(valid.string_is_not_empty("Empty")),
    )
    valid.ok(out)
  }

  None
  |> valid.validate(validator)
  |> should.equal(Ok(None))

  Some("Sam")
  |> valid.validate(validator)
  |> should.equal(Ok(Some("Sam")))

  Some("")
  |> valid.validate(validator)
  |> should.equal(Error(["Empty"]))
}

pub fn string_not_empty_test() {
  let validator = fn(input) {
    use out <- valid.check(input, valid.string_is_not_empty("Empty"))
    valid.ok(out)
  }

  "Hello"
  |> valid.validate(validator)
  |> should.equal(Ok("Hello"))

  ""
  |> valid.validate(validator)
  |> should.equal(Error(["Empty"]))
}

pub fn string_is_int_test() {
  let validator = fn(input) {
    use out <- valid.check(input, valid.string_is_int("NaN"))
    valid.ok(out)
  }

  "1"
  |> valid.validate(validator)
  |> should.equal(Ok(1))

  "1.2"
  |> valid.validate(validator)
  |> should.equal(Error(["NaN"]))

  "Hello"
  |> valid.validate(validator)
  |> should.equal(Error(["NaN"]))
}

pub fn string_is_float_test() {
  let validator = fn(input) {
    use out <- valid.check(input, valid.string_is_float("NaN"))
    valid.ok(out)
  }

  "1.1"
  |> valid.validate(validator)
  |> should.equal(Ok(1.1))

  "1"
  |> valid.validate(validator)
  |> should.equal(Ok(1.0))

  "Hello"
  |> valid.validate(validator)
  |> should.equal(Error(["NaN"]))
}

pub fn string_is_float_strict_test() {
  let validator = fn(input) {
    use out <- valid.check(input, valid.string_is_float_strict("NaN"))
    valid.ok(out)
  }

  "1.1"
  |> valid.validate(validator)
  |> should.equal(Ok(1.1))

  "1"
  |> valid.validate(validator)
  |> should.equal(Error(["NaN"]))

  "Hello"
  |> valid.validate(validator)
  |> should.equal(Error(["NaN"]))
}

pub fn is_ok_test() {
  let validator = fn(input) {
    use out <- valid.check(
      input,
      valid.is_ok(Active, status_from_code, function.identity),
    )
    valid.ok(out)
  }

  "Active"
  |> valid.validate(validator)
  |> should.equal(Ok(Active))

  "Pending"
  |> valid.validate(validator)
  |> should.equal(Error(["Invalid Pending"]))
}

pub fn then_test() {
  let validator = fn(input_name) {
    use name <- valid.check(
      input_name,
      valid.is_some("", valid.ok, "Input")
        |> valid.then(valid.string_min_length(2, "Size")),
    )

    valid.ok(name)
  }

  None
  |> valid.validate(validator)
  |> should.equal(Error(["Input"]))

  Some("")
  |> valid.validate(validator)
  |> should.equal(Error(["Size"]))

  Some("Sam")
  |> valid.validate(validator)
  |> should.equal(Ok("Sam"))
}

pub fn whole_test() {
  let validator = fn(tuple) {
    let #(password, confirmation) = tuple

    use password <- valid.check(password, valid.string_is_not_empty("Password"))

    use confirmation <- valid.check(
      confirmation,
      valid.string_is_not_empty("confirmation"),
    )

    case password == confirmation {
      True -> valid.ok(password)
      False -> valid.fail("", "No match")
    }
  }

  #("a", "a")
  |> valid.validate(validator)
  |> should.equal(Ok("a"))

  #("a", "b")
  |> valid.validate(validator)
  |> should.equal(Error(["No match"]))
}

pub fn transform_test() {
  let validator = fn(input) {
    use out <- valid.check(string.trim(input), valid.ok)

    valid.ok(out)
  }

  "    Sam   "
  |> valid.validate(validator)
  |> should.equal(Ok("Sam"))
}
