import gleam/dict.{type Dict}
import gleam/function
import gleam/list
import gleam/option.{type Option, None, Some}
import gleeunit
import gleeunit/should
import valid.{type Validator, type ValidatorResult}

type InputUser {
  InputUser(
    name: Option(String),
    email: Option(String),
    age: Int,
    weight: Option(Int),
  )
}

type ValidUser {
  ValidUser(name: String, email: String, age: Int, weight: Option(Int))
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
  valid.build4(ValidUser)
  |> valid.check(user.name, valid.is_some("Please provide a name"))
  |> valid.check(user.email, valid.is_some("Please provide an email"))
  |> valid.check(user.age, valid.ok())
  |> valid.keep(user.weight)
}

pub fn invalid_test() {
  let invalid = InputUser(name: None, email: None, age: 0, weight: None)

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
    InputUser(
      name: Some("Sam"),
      email: Some("sam@sample.com"),
      age: 11,
      weight: Some(20),
    )

  let valid =
    ValidUser(name: "Sam", email: "sam@sample.com", age: 11, weight: Some(20))

  user_validator(valid_input)
  |> should.equal(Ok(valid))
}

pub fn error_type_test() {
  let validator = fn(thing: Thing) {
    valid.build1(Thing)
    |> valid.check(thing.name, valid.string_is_not_empty(ErrorEmpty))
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

  let custom = valid.custom("Must be One", must_be_one)

  let validator = fn(thing: Thing) {
    valid.build1(Thing)
    |> valid.check(thing.name, custom)
  }

  let thing_one = Thing("One")

  validator(thing_one)
  |> should.equal(Ok(Thing("One")))

  let thing_two = Thing("Two")

  let expected_error = Error(#("Must be One", ["Must be One"]))

  validator(thing_two)
  |> should.equal(expected_error)
}

fn user_dict_validator(
  input: Dict(String, String),
) -> ValidatorResult(ValidUser, String) {
  let get_email = fn(d) { dict.get(d, "email") |> option.from_result }

  valid.build4(ValidUser)
  |> valid.check(
    input,
    valid.required_in_dict("name", "Missing name")
      |> valid.and_string_is_not_empty("Please provide a name"),
  )
  |> valid.check(
    input,
    valid.required_in(get_email, "Missing Email")
      |> valid.and_string_is_email("Please provide an email"),
  )
  |> valid.check(
    input,
    valid.required_in_dict("age", "Missing age")
      |> valid.and_string_is_int("Please provide an age"),
  )
  |> valid.check(
    input,
    valid.optional_in_dict("weight")
      |> valid.and_optional(valid.string_is_int("Please provide a valid number")),
  )
}

pub fn using_a_dictionary_test() {
  let values = [
    #("name", "Sam"),
    #("email", "sam@sample.com"),
    #("age", "18"),
    #("weight", "20"),
  ]
  let values_dict = dict.from_list(values)

  let valid =
    ValidUser(name: "Sam", email: "sam@sample.com", age: 18, weight: Some(20))

  user_dict_validator(values_dict)
  |> should.equal(Ok(valid))
}

pub fn and_test() {
  let name_validator =
    valid.string_is_not_empty("Empty")
    |> valid.and_string_min_length("More", 6)
    |> valid.and_string_max_length("Less", 2)

  let validator = fn(thing: Thing) {
    valid.build1(Thing)
    |> valid.check(thing.name, name_validator)
  }

  let thing = Thing("One")

  let expected_error = Error(#("More", ["More"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn and_with_transformation_test() {
  let name_validator =
    valid.is_some("Is null")
    |> valid.and(valid.string_is_not_empty("Empty"))
    |> valid.and(valid.string_min_length("More", 3))
    |> valid.and(valid.string_max_length("Less", 8))

  let validator = fn(thing: InputThing) {
    valid.build1(Thing)
    |> valid.check(thing.name, name_validator)
  }

  let thing = InputThing(Some("One Thing"))

  let expected_error = Error(#("Less", ["Less"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn all_test() {
  let name_validator =
    valid.all([
      valid.string_is_not_empty("Empty"),
      valid.string_min_length(">=3", 3),
      valid.string_min_length(">=4", 4),
      valid.string_min_length(">=5", 5),
      valid.string_max_length("<=10", 10),
    ])

  let validator = fn(thing: Thing) {
    valid.build1(Thing)
    |> valid.check(thing.name, name_validator)
  }

  let thing = Thing("1")

  let expected_error = Error(#(">=3", [">=3", ">=4", ">=5"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn compose_and_all_test() {
  let name_validator =
    valid.is_some("Is null")
    |> valid.and(
      valid.all([
        valid.string_is_not_empty("Empty"),
        valid.string_min_length(">=3", 3),
        valid.string_max_length("<=10", 10),
      ]),
    )

  let validator = fn(thing: InputThing) {
    valid.build1(Thing)
    |> valid.check(thing.name, name_validator)
  }

  let thing = InputThing(Some("One Thing after the other"))

  let expected_error = Error(#("<=10", ["<=10"]))

  validator(thing)
  |> should.equal(expected_error)
}

pub fn keep_test() {
  let validator = fn(thing: Thing) {
    valid.build1(Thing)
    |> valid.keep(thing.name)
  }

  validator(Thing(name: "Sam"))
  |> should.equal(Ok(Thing(name: "Sam")))
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
    valid.build2(Character)
    |> valid.check(c.level, valid.int_min("Level must be more that zero", 1))
    |> valid.check(
      c.strength,
      valid.int_min("Strength must be more that zero", 1),
    )
    |> valid.whole(whole_validator)
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
  let validator = valid.int_min(">=5", 5)

  validator(5)
  |> should.equal(Ok(5))

  let expected_error = Error(#(">=5", [">=5"]))

  validator(4)
  |> should.equal(expected_error)
}

pub fn int_max_test() {
  let validator = valid.int_max("<=5", 5)

  validator(5)
  |> should.equal(Ok(5))

  let expected_error = Error(#("<=5", ["<=5"]))

  validator(6)
  |> should.equal(expected_error)
}

pub fn list_is_not_empty_test() {
  let validator = valid.list_is_not_empty("Empty")

  validator([1])
  |> should.equal(Ok([1]))

  let expected_error = Error(#("Empty", ["Empty"]))

  validator([])
  |> should.equal(expected_error)
}

pub fn list_min_length_test() {
  let validator = valid.list_min_length("Short", 3)

  validator([1, 2, 3])
  |> should.equal(Ok([1, 2, 3]))

  let expected_error = Error(#("Short", ["Short"]))

  validator([1, 2])
  |> should.equal(expected_error)
}

pub fn list_max_length_test() {
  let validator = valid.list_max_length("Long", 4)

  validator([1, 2, 3])
  |> should.equal(Ok([1, 2, 3]))

  let expected_error = Error(#("Long", ["Long"]))

  validator([1, 2, 3, 4, 5])
  |> should.equal(expected_error)
}

pub fn list_all_test() {
  let list_validator = valid.list_every(valid.string_min_length("Short", 3))

  let validator = fn(thing: ThingWithList) {
    valid.build1(ThingWithList)
    |> valid.check(thing.items, list_validator)
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
  let validator = valid.is_some("Null")

  validator(Some("Hola"))
  |> should.equal(Ok("Hola"))

  let expected_error = Error(#("Null", ["Null"]))

  validator(None)
  |> should.equal(expected_error)
}

pub fn optional_test() {
  let validator = valid.optional(valid.string_min_length("Short", 3))

  validator(None)
  |> should.equal(Ok(None))

  validator(Some("abc"))
  |> should.equal(Ok(Some("abc")))

  let expected_error = Error(#("Short", ["Short"]))

  validator(Some("a"))
  |> should.equal(expected_error)
}

pub fn optional_different_type_test() {
  let validator = valid.optional(valid.string_is_int("Not Int"))

  validator(None)
  |> should.equal(Ok(None))

  validator(Some("1"))
  |> should.equal(Ok(Some(1)))

  let expected_error = Error(#("Not Int", ["Not Int"]))

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

pub fn optional_in_dict_test() {
  let validator = valid.optional_in_dict("key")

  validator(dict.new())
  |> should.equal(Ok(None))

  validator([#("key", 1)] |> dict.from_list)
  |> should.equal(Ok(Some(1)))
}

pub fn required_in_test() {
  let validator = valid.required_in(function.identity, "Absent")

  validator(None)
  |> should.equal(Error(#("Absent", ["Absent"])))

  validator(Some(1))
  |> should.equal(Ok(1))
}

pub fn required_in_dict_test() {
  let validator = valid.required_in_dict("name", "Absent")

  validator(dict.new())
  |> should.equal(Error(#("Absent", ["Absent"])))

  validator([#("name", "sam")] |> dict.from_list)
  |> should.equal(Ok("sam"))
}

pub fn string_not_empty_test() {
  let validator = valid.string_is_not_empty("Empty")

  validator("One")
  |> should.equal(Ok("One"))

  let expected_error = Error(#("Empty", ["Empty"]))

  validator("")
  |> should.equal(expected_error)
}

pub fn string_is_int_test() {
  let validator = valid.string_is_int("NaN")

  validator("1")
  |> should.equal(Ok(1))

  let expected_error = Error(#("NaN", ["NaN"]))

  validator("A")
  |> should.equal(expected_error)
}

pub fn string_is_float_test() {
  let validator = valid.string_is_float("NaN")

  validator("1.1")
  |> should.equal(Ok(1.1))

  let expected_error = Error(#("NaN", ["NaN"]))

  validator("A")
  |> should.equal(expected_error)
}

pub fn string_is_email_test() {
  let validator = valid.string_is_email("Not email")

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
  let validator = valid.string_min_length("Less than 3", 3)

  validator("One")
  |> should.equal(Ok("One"))

  let expected_error = Error(#("Less than 3", ["Less than 3"]))

  validator("Tw")
  |> should.equal(expected_error)
}

pub fn string_max_length_test() {
  let validator = valid.string_max_length("More than 5", 5)

  validator("Hello")
  |> should.equal(Ok("Hello"))

  let expected_error = Error(#("More than 5", ["More than 5"]))

  validator("More than five")
  |> should.equal(expected_error)
}

pub fn nested_test() {
  let thing_validator = fn(thing: InputThing) {
    valid.build1(Thing)
    |> valid.check(thing.name, valid.is_some("Is null"))
  }

  let things_validator = valid.list_every(thing_validator)

  let validator = fn(col: InputCollection) {
    valid.build2(ValidCollection)
    |> valid.check(col.thing, thing_validator)
    |> valid.check(col.things, things_validator)
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
