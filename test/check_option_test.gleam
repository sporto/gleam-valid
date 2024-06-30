import gleam/function
import gleam/option.{type Option, None, Some}
import gleeunit/should
import valid

pub fn is_some_test() {
  let validator = valid.is_some("Null")

  validator(Some("Hola"))
  |> should.equal(Ok("Hola"))

  let expected_error = Error(valid.non_empty_new("Null", []))

  validator(None)
  |> should.equal(expected_error)
}

pub fn optional_test() {
  let validator = valid.optional(valid.string_min_length(3, "Short"))

  validator(None)
  |> should.equal(Ok(None))

  validator(Some("abc"))
  |> should.equal(Ok(Some("abc")))

  let expected_error = Error(valid.non_empty_new("Short", []))

  validator(Some("a"))
  |> should.equal(expected_error)
}

pub fn optional_different_type_test() {
  let validator = valid.optional(valid.string_is_int("Not Int"))

  validator(None)
  |> should.equal(Ok(None))

  validator(Some("1"))
  |> should.equal(Ok(Some(1)))

  let expected_error = Error(valid.non_empty_new("Not Int", []))

  validator(Some("a"))
  |> should.equal(expected_error)
}

pub fn optional_in_test() {
  let validator = valid.optional_in(function.identity)

  validator(None)
  |> should.equal(Ok(None))

  validator(Some(1))
  |> should.equal(Ok(Some(1)))
}

pub fn required_in_test() {
  let validator = valid.required_in(function.identity, "Absent")

  validator(None)
  |> should.equal(Error(valid.non_empty_new("Absent", [])))

  validator(Some(1))
  |> should.equal(Ok(1))
}
