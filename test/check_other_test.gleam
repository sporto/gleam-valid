import gleam/string
import gleeunit/should
import valid.{type ValidatorResult}

type User {
  User(name: String, email: String)
}

pub fn check_only_test() {
  let name_and_email_error = "Your email must contain your name"

  let name_and_email_validator = fn(input: User) {
    case string.contains(input.email, input.name) {
      True -> Ok(input)
      False -> Error(valid.non_empty_new(name_and_email_error, []))
    }
  }

  let user_validator = fn(input: User) {
    valid.build2(User)
    |> valid.check_only(input, name_and_email_validator)
    |> valid.check(input.name, valid.string_is_not_empty("Missing name"))
    |> valid.check(input.email, valid.string_is_not_empty("Missing Email"))
  }

  let user_1 = User(name: "sam", email: "sam@sample.com")

  user_validator(user_1)
  |> should.equal(Ok(user_1))

  let user_2 = User(name: "julia", email: "sam@sample.com")

  user_validator(user_2)
  |> should.equal(Error(valid.non_empty_new(name_and_email_error, [])))
}
