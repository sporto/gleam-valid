import gleam/string
import gleeunit/should
import valid

type ValidUser {
  ValidUser(name: String, email: String)
}

pub fn check_only_test() {
  let name_and_email_error = "Your email must contain your name"

  let name_and_email_validator = fn(input: ValidUser) {
    case string.contains(input.email, input.name) {
      True -> Ok(input)
      False -> Error(valid.non_empty_new(name_and_email_error, []))
    }
  }

  let user_validator = fn(input: ValidUser) {
    valid.build2(ValidUser)
    |> valid.check_only(input, name_and_email_validator)
    |> valid.check(input.name, valid.string_is_not_empty("Missing name"))
    |> valid.check(input.email, valid.string_is_not_empty("Missing Email"))
  }

  let user_1 = ValidUser(name: "sam", email: "sam@sample.com")

  user_validator(user_1)
  |> should.equal(Ok(user_1))

  let user_2 = ValidUser(name: "julia", email: "sam@sample.com")

  user_validator(user_2)
  |> should.equal(Error(valid.non_empty_new(name_and_email_error, [])))
}

pub fn keep_test() {
  let validator = fn(user: ValidUser) {
    valid.build2(ValidUser)
    |> valid.keep(user.name)
    |> valid.keep(user.email)
  }

  let user = ValidUser(name: "Sam", email: "email")

  validator(user)
  |> should.equal(Ok(user))
}
