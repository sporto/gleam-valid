import validator
import validator/option as v_option
import validator/string as v_string
import gleam/should
import gleam/option.{None, Option, Some}

type DirtyUser {
  DirtyUser(name: Option(String), email: Option(String), age: Int)
}

type ValidUser {
  ValidUser(name: String, email: String, age: Int)
}

fn user_validator(user: DirtyUser) -> Result(ValidUser, List(String)) {
  validator.begin3(ValidUser)
  |> validator.validate(user.name, v_option.is_some("Please provide a name"))
  |> validator.validate(user.email, v_option.is_some("Please provide an email"))
  |> validator.keep(user.age)
}

pub fn invalid_test() {
  let invalid = DirtyUser(name: None, email: None, age: 0)

  user_validator(invalid)
  |> should.equal(Error(["Please provide a name", "Please provide an email"]))
}

pub fn valid_test() {
  let valid_input =
    DirtyUser(name: Some("Sam"), email: Some("sam@sample.com"), age: 11)

  let valid = ValidUser(name: "Sam", email: "sam@sample.com", age: 11)

  user_validator(valid_input)
  |> should.equal(Ok(valid))
}

type Thing {
  Thing(name: String)
}

pub fn custom_validator_test() {
  let must_be_one = fn(name: String) { name == "One" }

  let custom_validator = validator.custom_validator("Must be One", must_be_one)

  let validator = fn(thing: Thing) {
    validator.begin1(Thing)
    |> validator.validate(thing.name, custom_validator)
  }

  let thing_one = Thing("One")

  validator(thing_one)
  |> should.equal(Ok(Thing("One")))

  let thing_two = Thing("Two")

  validator(thing_two)
  |> should.equal(Error(["Must be One"]))
}

pub fn string_not_empty() {
  let validator = fn(thing: Thing) {
    validator.begin1(Thing)
    |> validator.validate(thing.name, v_string.is_not_empty("Empty"))
  }

  let thing_one = Thing("One")

  validator(thing_one)
  |> should.equal(Ok(Thing("One")))

  let thing_two = Thing("")

  validator(thing_two)
  |> should.equal(Error(["Empty"]))
}
