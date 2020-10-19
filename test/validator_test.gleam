import validator
import validator/option as v_option
import validator/string as v_string
import gleam/should
import gleam/option.{None, Option, Some}

type InputUser {
	InputUser(name: Option(String), email: Option(String), age: Int)
}

type ValidUser {
	ValidUser(name: String, email: String, age: Int)
}

type Thing {
	Thing(name: String)
}

type Error {
	ErrorEmpty
}

fn user_validator(user: InputUser) -> Result(ValidUser, List(String)) {
	validator.build3(ValidUser)
	|> validator.validate(user.name, v_option.is_some("Please provide a name"))
	|> validator.validate(user.email, v_option.is_some("Please provide an email"))
	|> validator.keep(user.age)
}

pub fn invalid_test() {
	let invalid = InputUser(name: None, email: None, age: 0)

	user_validator(invalid)
	|> should.equal(Error(["Please provide a name", "Please provide an email"]))
}

pub fn valid_test() {
	let valid_input = InputUser(
		name: Some("Sam"),
		email: Some("sam@sample.com"),
		age: 11
	)

	let valid = ValidUser(
		name: "Sam",
		email: "sam@sample.com",
		age: 11
	)

	user_validator(valid_input)
	|> should.equal(Ok(valid))
}

pub fn error_type_test() {
	let validator = fn(thing: Thing) {
		validator.build1(Thing)
		|> validator.validate(thing.name, v_string.is_not_empty(ErrorEmpty))
	}

	let thing = Thing("")

	validator(thing)
	|> should.equal(Error([ErrorEmpty]))
}

pub fn custom_validator_test() {
	let must_be_one = fn(name: String) -> Option(String) {
		case name == "One" {
			True ->
				Some(name)
			False ->
				None
		}
	}

	let custom_validator = validator.custom_validator("Must be One", must_be_one)

	let validator = fn(thing: Thing) {
		validator.build1(Thing)
		|> validator.validate(thing.name, custom_validator)
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("Two")

	validator(thing_two)
	|> should.equal(Error(["Must be One"]))
}

pub fn string_not_empty_test() {
	let validator = fn(thing: Thing) {
		validator.build1(Thing)
		|> validator.validate(thing.name, v_string.is_not_empty("Empty"))
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("")

	validator(thing_two)
	|> should.equal(Error(["Empty"]))
}

pub fn string_min_length_test() {
	let validator = fn(thing: Thing) {
		validator.build1(Thing)
		|> validator.validate(thing.name, v_string.min_length("Less than 3", 3))
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("Tw")

	validator(thing_two)
	|> should.equal(Error(["Less than 3"]))
}

pub fn string_max_length_test() {
	let validator = fn(thing: Thing) {
		validator.build1(Thing)
		|> validator.validate(thing.name, v_string.max_length("More than 5", 5))
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("Two and Three")

	validator(thing_two)
	|> should.equal(Error(["More than 5"]))
}
