import validator
import validator/option as v_option
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

fn user_validator(user: DirtyUser) -> Result(ValidUser, List(String)) {
	Ok(validator.map3(ValidUser))
	|> validator.validate(user.name, v_option.is_some("Please provide a name"))
	|> validator.validate(user.email, v_option.is_some("Please provide an email"))
	|> validator.keep(user.age)
}

pub fn invalid_test() {
	let invalid = DirtyUser(
		name: None,
		email: None,
		age: 0,
	)

	user_validator(invalid)
	|> should.equal(Error(["Please provide a name", "Please provide an email"]))
}

pub fn valid_test() {
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
