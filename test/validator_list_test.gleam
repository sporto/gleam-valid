import gleeunit/should
import non_empty_list
import valid

pub fn list_is_not_empty_test() {
  let validator = valid.list_is_not_empty("Empty")

  validator([1])
  |> should.equal(Ok([1]))

  let expected_error = Error(non_empty_list.new("Empty", []))

  validator([])
  |> should.equal(expected_error)
}

pub fn list_min_length_test() {
  let validator = valid.list_min_length(3, "Short")

  validator([1, 2, 3])
  |> should.equal(Ok([1, 2, 3]))

  let expected_error = Error(non_empty_list.new("Short", []))

  validator([1, 2])
  |> should.equal(expected_error)
}

pub fn list_max_length_test() {
  let validator = valid.list_max_length(4, "Long")

  validator([1, 2, 3])
  |> should.equal(Ok([1, 2, 3]))

  let expected_error = Error(non_empty_list.new("Long", []))

  validator([1, 2, 3, 4, 5])
  |> should.equal(expected_error)
}

pub fn list_every_test() {
  let validator = valid.list_every(valid.string_min_length(3, "Short"))

  validator(["One", "Two"])
  |> should.equal(Ok(["One", "Two"]))

  let expected_error = Error(non_empty_list.new("Short", ["Short"]))

  validator(["One", "T", "A"])
  |> should.equal(expected_error)
}
