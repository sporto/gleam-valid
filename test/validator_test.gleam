import validator.{ValidatorResult} as v
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

type InputThing {
	InputThing(name: Option(String))
}

type Thing {
	Thing(name: String)
}

type Error {
	ErrorEmpty
}

fn user_validator(user: InputUser) -> ValidatorResult(ValidUser, String) {
	v.build3(ValidUser)
	|> v.validate(
		user.name,
		v_option.is_some("Please provide a name")
	)
	|> v.validate(
		user.email,
		v_option.is_some("Please provide an email")
	)
	|> v.keep(user.age)
}

pub fn invalid_test() {
	let invalid = InputUser(name: None, email: None, age: 0)

	let expected = Error(
		tuple(
			"Please provide a name",
			["Please provide a name", "Please provide an email"]
		)
	)

	user_validator(invalid)
	|> should.equal(expected)
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
		v.build1(Thing)
		|> v.validate(thing.name, v_string.is_not_empty(ErrorEmpty))
	}

	let thing = Thing("")

	let expected = Error(tuple(ErrorEmpty, [ErrorEmpty]))

	validator(thing)
	|> should.equal(expected)
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

	let custom_validator = v.custom_validator("Must be One", must_be_one)

	let validator = fn(thing: Thing) {
		v.build1(Thing)
		|> v.validate(thing.name, custom_validator)
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("Two")

	let expected_error = Error(tuple("Must be One", ["Must be One"]))

	validator(thing_two)
	|> should.equal(expected_error)
}

pub fn and_test() {
	let name_validator = v_string.is_not_empty("Empty")
		|> v.and(v_string.min_length("More", 6))
		|> v.and(v_string.max_length("Less", 2))

	let validator = fn(thing: Thing) {
		v.build1(Thing)
		|> v.validate(thing.name, name_validator)
	}

	let thing = Thing("One")

	let expected_error = Error(
		tuple("More", ["More"])
	)

	validator(thing)
	|> should.equal(expected_error)
}

pub fn and_with_transformation_test() {
	let name_validator = v_option.is_some("Is null")
		|> v.and(v_string.is_not_empty("Empty"))
		|> v.and(v_string.min_length("More", 3))
		|> v.and(v_string.max_length("Less", 8))

	let validator = fn(thing: InputThing) {
		v.build1(Thing)
		|> v.validate(thing.name, name_validator)
	}

	let thing = InputThing(Some("One Thing"))

	let expected_error = Error(
		tuple("Less", ["Less"])
	)

	validator(thing)
	|> should.equal(expected_error)
}

pub fn string_not_empty_test() {
	let validator = fn(thing: Thing) {
		v.build1(Thing)
		|> v.validate(thing.name, v_string.is_not_empty("Empty"))
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("")

	let expected_error = Error(tuple("Empty", ["Empty"]))

	validator(thing_two)
	|> should.equal(expected_error)
}

pub fn string_min_length_test() {
	let validator = fn(thing: Thing) {
		v.build1(Thing)
		|> v.validate(thing.name, v_string.min_length("Less than 3", 3))
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("Tw")

	let expected_error = Error(tuple("Less than 3", ["Less than 3"]))

	validator(thing_two)
	|> should.equal(expected_error)
}

pub fn string_max_length_test() {
	let validator = fn(thing: Thing) {
		v.build1(Thing)
		|> v.validate(thing.name, v_string.max_length("More than 5", 5))
	}

	let thing_one = Thing("One")

	validator(thing_one)
	|> should.equal(Ok(Thing("One")))

	let thing_two = Thing("Two and Three")

	let expected_error = Error(tuple("More than 5", ["More than 5"]))

	validator(thing_two)
	|> should.equal(expected_error)
}
