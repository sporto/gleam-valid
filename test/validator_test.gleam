import validator
import gleam/should
import gleam/option.{None, Option, Some}

type DirtyUser {
  DirtyUser(
    name: Option(String),
    email: Option(String),
    age: Int,
  )
}

type ValidUser {
  ValidUser(
    name: String,
    email: String,
    age: Int,
  )
}

fn make_valid_user(name: String) {
  fn(email: String) {
    fn(age: Int) -> ValidUser {
      ValidUser(
        name: name,
        email: email,
        age: age,
      )
    }
  }
}

fn user_validator(user: DirtyUser) {
  Ok(make_valid_user)
  |> validator.validate(user.name, validator.not_maybe)
  |> validator.validate(user.email, validator.not_maybe)
  |> validator.keep(user.age)
}

pub fn validator_test() {
  let invalid = DirtyUser(
    name: None,
    email: None,
    age: 0,
  )

  user_validator(invalid)
  |> should.equal(Error("Is none"))

  let valid_input = DirtyUser(
    name: Some("Sam"),
    email: Some("sam@sample.com"),
    age: 11,
  )

  let valid = ValidUser(
    name: "Sam",
    email: "sam@sample.com",
    age: 11,
  )

  user_validator(valid_input)
  |> should.equal(Ok(valid))
}
