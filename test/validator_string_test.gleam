import gleam/list
import gleeunit/should
import non_empty_list
import valid

pub fn string_not_empty_test() {
  let validator = valid.string_is_not_empty("Empty")

  validator("One")
  |> should.equal(Ok("One"))

  let expected_error = Error(non_empty_list.new("Empty", []))

  validator("")
  |> should.equal(expected_error)
}

pub fn string_is_int_test() {
  let validator = valid.string_is_int("NaN")

  validator("1")
  |> should.equal(Ok(1))

  let expected_error = Error(non_empty_list.new("NaN", []))

  validator("A")
  |> should.equal(expected_error)
}

pub fn string_is_float_test() {
  let validator = valid.string_is_float("NaN")

  validator("1.1")
  |> should.equal(Ok(1.1))

  let expected_error = Error(non_empty_list.new("NaN", []))

  validator("A")
  |> should.equal(expected_error)
}

pub fn string_is_email_test() {
  let validator = valid.string_is_email("Not email")

  ["a@b", "a1@b", "a1@b.com", "a1@b.com.au", "firstname.lastname@b.com"]
  |> list.map(fn(email) {
    validator(email)
    |> should.equal(Ok(email))
  })

  let expected_error = Error(non_empty_list.new("Not email", []))

  ["", "a", "a@", "@b", ".@b", "a.a.a@b.com"]
  |> list.map(fn(email) {
    validator(email)
    |> should.equal(expected_error)
  })
}

pub fn string_min_length_test() {
  let validator = valid.string_min_length(3, "Less than 3")

  validator("One")
  |> should.equal(Ok("One"))

  let expected_error = Error(non_empty_list.new("Less than 3", []))

  validator("Tw")
  |> should.equal(expected_error)
}

pub fn string_max_length_test() {
  let validator = valid.string_max_length(5, "More than 5")

  validator("Hello")
  |> should.equal(Ok("Hello"))

  let expected_error = Error(non_empty_list.new("More than 5", []))

  validator("More than five")
  |> should.equal(expected_error)
}
