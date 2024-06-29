import gleam/list
import gleam/option.{type Option, None, Some}
import gleeunit
import gleeunit/should
import valid as v
import valid/vcommon.{type ValidatorResult}
import valid/vint
import valid/vlist
import valid/voption
import valid/vstring

type InputUser {
  InputUser(name: Option(String), email: Option(String), age: Int)
}

type ValidUser {
  ValidUser(name: String, email: String, age: Int)
}

type InputThing {
  InputThing(name: Option(String))
}

type Thing {
  Thing(name: String)
}

type ThingWithList {
  ThingWithList(items: List(String))
}

type Character {
  Character(level: Int, strength: Int)
}

type InputCollection {
  InputCollection(thing: InputThing, things: List(InputThing))
}

type ValidCollection {
  ValidCollection(thing: Thing, things: List(Thing))
}

type Error {
  ErrorEmpty
}

pub fn main() {
  gleeunit.main()
}

fn user_validator(user: InputUser) -> ValidatorResult(ValidUser, String) {
  v.build3(ValidUser)
  |> v.validate(user.name, voption.is_some("Please provide a name"))
  |> v.validate(user.email, voption.is_some("Please provide an email"))
  |> v.keep(user.age)
}

pub fn invalid_test() {
  let invalid = InputUser(name: None, email: None, age: 0)

  let expected =
    Error(
      #("Please provide a name", [
        "Please provide a name", "Please provide an email",
      ]),
    )

  user_validator(invalid)
  |> should.equal(expected)
}

pub fn valid_test() {
  let valid_input =
    InputUser(name: Some("Sam"), email: Some("sam@sample.com"), age: 11)

  let valid = ValidUser(name: "Sam", email: "sam@sample.com", age: 11)

  user_validator(valid_input)
  |> should.equal(Ok(valid))
}

pub fn error_type_test() {
  let validator = fn(thing: Thing) {
    v.build1(Thing)
    |> v.validate(thing.name, vstring.is_not_empty(ErrorEmpty))
  }

  let thing = Thing("")

  let expected = Error(#(ErrorEmpty, [ErrorEmpty]))

  validator(thing)
  |> should.equal(expected)
}

pub fn custom_test() {
  let must_be_one = fn(name: String) -> Option(String) {
    case name == "One" {
      True -> Some(name)
      False -> None
    }
  }

  let custom = v.custom("Must be One", must_be_one)

  let validator = fn(thing: Thing) {
    v.build1(Thing)
    |> v.validate(thing.name, custom)
  }

  let thing_one = Thing("One")

  validator(thing_one)
  |> should.equal(Ok(Thing("One")))

  let thing_two = Thing("Two")

  let expected_error = Error(#("Must be One", ["Must be One"]))

  validator(thing_two)
  |> should.equal(expected_error)
}

pub fn and_test() {
  let name_validator =
    vstring.is_not_empty("Empty")
    |> v.and(vstring.min_length("More", 6))
    |> v.and(vstring.max_length("Less", 2))

  let validator = fn(thing: Thing) {
    v.build1(Thing)
    |> v.validate(thing.name, name_validator)
  }

  let thing = Thing("One")

  let expected_error = Error(#("More", ["More"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn and_with_transformation_test() {
  let name_validator =
    voption.is_some("Is null")
    |> v.and(vstring.is_not_empty("Empty"))
    |> v.and(vstring.min_length("More", 3))
    |> v.and(vstring.max_length("Less", 8))

  let validator = fn(thing: InputThing) {
    v.build1(Thing)
    |> v.validate(thing.name, name_validator)
  }

  let thing = InputThing(Some("One Thing"))

  let expected_error = Error(#("Less", ["Less"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn all_test() {
  let name_validator =
    v.all([
      vstring.is_not_empty("Empty"),
      vstring.min_length(">=3", 3),
      vstring.min_length(">=4", 4),
      vstring.min_length(">=5", 5),
      vstring.max_length("<=10", 10),
    ])

  let validator = fn(thing: Thing) {
    v.build1(Thing)
    |> v.validate(thing.name, name_validator)
  }

  let thing = Thing("1")

  let expected_error = Error(#(">=3", [">=3", ">=4", ">=5"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn compose_and_all_test() {
  let name_validator =
    voption.is_some("Is null")
    |> v.and(
      v.all([
        vstring.is_not_empty("Empty"),
        vstring.min_length(">=3", 3),
        vstring.max_length("<=10", 10),
      ]),
    )

  let validator = fn(thing: InputThing) {
    v.build1(Thing)
    |> v.validate(thing.name, name_validator)
  }

  let thing = InputThing(Some("One Thing after the other"))

  let expected_error = Error(#("<=10", ["<=10"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn whole_test() {
  let error = "Strength cannot be less than level"

  let whole_validator = fn(c: Character) {
    case c.level > c.strength {
      True -> Error(error)
      False -> Ok(c)
    }
  }

  let validator = fn(c: Character) {
    v.build2(Character)
    |> v.validate(c.level, vint.min("Level must be more that zero", 1))
    |> v.validate(c.strength, vint.min("Strength must be more that zero", 1))
    |> v.whole(whole_validator)
  }

  let char = Character(level: 1, strength: 1)

  validator(char)
  |> should.equal(Ok(char))

  let char2 = Character(level: 2, strength: 1)

  validator(char2)
  |> should.equal(Error(#(error, [error])))
}

// Validators

pub fn int_min_test() {
  let validator = vint.min(">=5", 5)

  validator(5)
  |> should.equal(Ok(5))

  let expected_error = Error(#(">=5", [">=5"]))

  validator(4)
  |> should.equal(expected_error)
}

pub fn int_max_test() {
  let validator = vint.max("<=5", 5)

  validator(5)
  |> should.equal(Ok(5))

  let expected_error = Error(#("<=5", ["<=5"]))

  validator(6)
  |> should.equal(expected_error)
}

pub fn list_is_not_empty_test() {
  let validator = vlist.is_not_empty("Empty")

  validator([1])
  |> should.equal(Ok([1]))

  let expected_error = Error(#("Empty", ["Empty"]))

  validator([])
  |> should.equal(expected_error)
}

pub fn list_min_length_test() {
  let validator = vlist.min_length("Short", 3)

  validator([1, 2, 3])
  |> should.equal(Ok([1, 2, 3]))

  let expected_error = Error(#("Short", ["Short"]))

  validator([1, 2])
  |> should.equal(expected_error)
}

pub fn list_max_length_test() {
  let validator = vlist.max_length("Long", 4)

  validator([1, 2, 3])
  |> should.equal(Ok([1, 2, 3]))

  let expected_error = Error(#("Long", ["Long"]))

  validator([1, 2, 3, 4, 5])
  |> should.equal(expected_error)
}

pub fn list_all_test() {
  let list_validator = vlist.every(vstring.min_length("Short", 3))

  let validator = fn(thing: ThingWithList) {
    v.build1(ThingWithList)
    |> v.validate(thing.items, list_validator)
  }

  let thing = ThingWithList(["One", "Two"])

  validator(thing)
  |> should.equal(Ok(thing))

  let thing2 = ThingWithList(["One", "T", "A"])

  let expected_error = Error(#("Short", ["Short", "Short"]))

  validator(thing2)
  |> should.equal(expected_error)
}

pub fn option_is_some_test() {
  let validator = voption.is_some("Null")

  validator(Some("Hola"))
  |> should.equal(Ok("Hola"))

  let expected_error = Error(#("Null", ["Null"]))

  validator(None)
  |> should.equal(expected_error)
}

pub fn option_optional_test() {
  let validator = voption.optional(vstring.min_length("Short", 3))

  validator(None)
  |> should.equal(Ok(None))

  validator(Some("abc"))
  |> should.equal(Ok(Some("abc")))

  let expected_error = Error(#("Short", ["Short"]))

  validator(Some("a"))
  |> should.equal(expected_error)
}

pub fn string_not_empty_test() {
  let validator = vstring.is_not_empty("Empty")

  validator("One")
  |> should.equal(Ok("One"))

  let expected_error = Error(#("Empty", ["Empty"]))

  validator("")
  |> should.equal(expected_error)
}

pub fn string_is_int_test() {
  let validator = vstring.is_int("NaN")

  validator("1")
  |> should.equal(Ok(1))

  let expected_error = Error(#("NaN", ["NaN"]))

  validator("A")
  |> should.equal(expected_error)
}

pub fn string_is_float_test() {
  let validator = vstring.is_float("NaN")

  validator("1.1")
  |> should.equal(Ok(1.1))

  let expected_error = Error(#("NaN", ["NaN"]))

  validator("A")
  |> should.equal(expected_error)
}

pub fn string_is_email_test() {
  let validator = vstring.is_email("Not email")

  ["a@b", "a1@b", "a1@b.com", "a1@b.com.au"]
  |> list.map(fn(email) {
    validator(email)
    |> should.equal(Ok(email))
  })

  let expected_error = Error(#("Not email", ["Not email"]))

  ["", "a", "a@", "@b"]
  |> list.map(fn(email) {
    validator(email)
    |> should.equal(expected_error)
  })
}

pub fn string_min_length_test() {
  let validator = vstring.min_length("Less than 3", 3)

  validator("One")
  |> should.equal(Ok("One"))

  let expected_error = Error(#("Less than 3", ["Less than 3"]))

  validator("Tw")
  |> should.equal(expected_error)
}

pub fn string_max_length_test() {
  let validator = vstring.max_length("More than 5", 5)

  validator("Hello")
  |> should.equal(Ok("Hello"))

  let expected_error = Error(#("More than 5", ["More than 5"]))

  validator("More than five")
  |> should.equal(expected_error)
}

pub fn nested_test() {
  let thing_validator = fn(thing: InputThing) {
    v.build1(Thing)
    |> v.validate(thing.name, voption.is_some("Is null"))
  }

  let things_validator = vlist.every(thing_validator)

  let validator = fn(col: InputCollection) {
    v.build2(ValidCollection)
    |> v.validate(col.thing, thing_validator)
    |> v.validate(col.things, things_validator)
  }

  let input_col_1 =
    InputCollection(thing: InputThing(name: Some("One")), things: [
      InputThing(name: Some("Two")),
      InputThing(name: Some("Three")),
    ])

  let valid_col1 =
    ValidCollection(thing: Thing(name: "One"), things: [
      Thing(name: "Two"),
      Thing(name: "Three"),
    ])

  validator(input_col_1)
  |> should.equal(Ok(valid_col1))

  let input_col_2 =
    InputCollection(thing: InputThing(name: Some("One")), things: [
      InputThing(name: None),
      InputThing(name: Some("Three")),
    ])

  let expected_error = Error(#("Is null", ["Is null"]))

  validator(input_col_2)
  |> should.equal(expected_error)
}
