import gleam/option.{type Option, None, Some}
import gleeunit/should
import valid

pub fn then_test() {
  let validator =
    valid.string_is_not_empty("Empty")
    |> valid.then(valid.string_min_length(6, "More"))
    |> valid.then(valid.string_max_length(2, "Less"))

  let expected_error = Error(valid.non_empty_new("More", []))

  validator("One")
  |> should.equal(expected_error)
}

pub fn and_with_transformation_test() {
  let validator =
    valid.is_some("Is null")
    |> valid.then(valid.string_is_not_empty("Empty"))
    |> valid.then(valid.string_min_length(3, "More"))
    |> valid.then(valid.string_max_length(8, "Less"))

  let expected_error = Error(valid.non_empty_new("Less", []))

  validator(Some("One Thing"))
  |> should.equal(expected_error)
}

pub fn all_test() {
  let validator =
    valid.all([
      valid.string_is_not_empty("Empty"),
      valid.string_min_length(3, ">=3"),
      valid.string_min_length(4, ">=4"),
      valid.string_min_length(5, ">=5"),
      valid.string_max_length(10, "<=10"),
    ])

  let expected_error = Error(valid.non_empty_new(">=3", [">=4", ">=5"]))

  validator("1")
  |> should.equal(expected_error)
}

pub fn compose_and_all_test() {
  let validator =
    valid.is_some("Is null")
    |> valid.then(
      valid.all([
        valid.string_is_not_empty("Empty"),
        valid.string_min_length(3, ">=3"),
        valid.string_max_length(10, "<=10"),
      ]),
    )

  let expected_error = Error(valid.non_empty_new("<=10", []))

  validator(Some("One thing after the other"))
  |> should.equal(expected_error)
}

type UserInput {
  UserInput(name: Option(String))
}

type User {
  User(name: String)
}

type InputCollection {
  InputCollection(thing: UserInput, things: List(UserInput))
}

type ValidCollection {
  ValidCollection(thing: User, things: List(User))
}

fn user_validator(user: UserInput) {
  valid.build1(User)
  |> valid.check(user.name, valid.is_some("Is null"))
}

pub fn nested_test() {
  let users_validator = valid.list_every(user_validator)

  let validator = fn(col: InputCollection) {
    valid.build2(ValidCollection)
    |> valid.check(col.thing, user_validator)
    |> valid.check(col.things, users_validator)
  }

  let input_col_1 =
    InputCollection(thing: UserInput(name: Some("One")), things: [
      UserInput(name: Some("Two")),
      UserInput(name: Some("Three")),
    ])

  let valid_col1 =
    ValidCollection(thing: User(name: "One"), things: [
      User(name: "Two"),
      User(name: "Three"),
    ])

  validator(input_col_1)
  |> should.equal(Ok(valid_col1))

  let input_col_2 =
    InputCollection(thing: UserInput(name: Some("One")), things: [
      UserInput(name: None),
      UserInput(name: Some("Three")),
    ])

  let expected_error = Error(valid.non_empty_new("Is null", []))

  validator(input_col_2)
  |> should.equal(expected_error)
}
