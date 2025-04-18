import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleeunit/should
import non_empty_list
import valid.{type ValidatorResult}

type ValidUser {
  ValidUser(name: String, email: String, age: Int, weight: Option(Int))
}

fn user_dict_validator(
  input: Dict(String, String),
) -> ValidatorResult(ValidUser, String) {
  let get_email = dict.get(_, "email")

  valid.build4(ValidUser)
  |> valid.check(
    input,
    valid.required_in_dict("name", "Missing name")
      |> valid.then(valid.string_is_not_empty("Please provide a name")),
  )
  |> valid.check(
    input,
    valid.required_in(get_email, "Missing Email")
      |> valid.then(valid.string_is_email("Please provide an email")),
  )
  |> valid.check(
    input,
    valid.required_in_dict("age", "Missing age")
      |> valid.then(valid.string_is_int("Please provide an age")),
  )
  |> valid.check(
    input,
    valid.optional_in_dict("weight")
      |> valid.then(
        valid.if_some(valid.string_is_int("Please provide a valid number")),
      ),
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

pub fn required_in_dict_test() {
  let validator = valid.required_in_dict("name", "Absent")

  validator(dict.new())
  |> should.equal(Error(non_empty_list.new("Absent", [])))

  validator([#("name", "sam")] |> dict.from_list)
  |> should.equal(Ok("sam"))
}

pub fn optional_in_dict_test() {
  let validator = valid.optional_in_dict("key")

  validator(dict.new())
  |> should.equal(Ok(None))

  validator([#("key", 1)] |> dict.from_list)
  |> should.equal(Ok(Some(1)))
}
