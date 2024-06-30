import gleeunit/should
import valid

type Thing {
  Thing(name: String)
}

fn must_be_one(name: String) -> Result(String, String) {
  case name == "One" {
    True -> Ok(name)
    False -> Error("Must be One")
  }
}

pub fn custom_test() {
  let custom = valid.custom(must_be_one)

  let validator = fn(thing: Thing) {
    valid.build1(Thing)
    |> valid.check(thing.name, custom)
  }

  validator(Thing("One"))
  |> should.equal(Ok(Thing("One")))

  let expected_error = Error(valid.non_empty_new("Must be One", []))

  validator(Thing("Two"))
  |> should.equal(expected_error)
}
