import gleeunit/should
import non_empty_list
import valid.{type ValidatorResult}

type Thing {
  Thing(name: String)
}

fn must_be_one(name: String) -> ValidatorResult(String, String) {
  case name == "One" {
    True -> Ok(name)
    False -> Error(non_empty_list.new("Must be One", []))
  }
}

pub fn custom_test() {
  let validator = fn(thing: Thing) {
    valid.build1(Thing)
    |> valid.check(thing.name, must_be_one)
  }

  validator(Thing("One"))
  |> should.equal(Ok(Thing("One")))

  let expected_error = Error(non_empty_list.new("Must be One", []))

  validator(Thing("Two"))
  |> should.equal(expected_error)
}
