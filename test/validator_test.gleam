import validator as v
import validator/int as v_int
import validator/list as v_list
import validator/option as v_option
import validator/string as v_string
import validator/common.{ValidatorResult}
import gleam/should
import gleam/list
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

type ThingWithList {
	ThingWithList(items: List(String))
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

pub fn custom_test() {
	let must_be_one = fn(name: String) -> Option(String) {
		case name == "One" {
			True ->
				Some(name)
			False ->
				None
		}
	}

	let custom = v.custom("Must be One", must_be_one)

	let validator = fn(thing: Thing) {
		v.build1(Thing)
		|> v.validate(thing.name, custom)
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

pub fn all_test() {
	let name_validator = v.all(
		[
			v_string.is_not_empty("Empty"),
			v_string.min_length(">=3", 3),
			v_string.min_length(">=4", 4),
			v_string.min_length(">=5", 5),
			v_string.max_length("<=10", 10)
		]
	)

	let validator = fn(thing: Thing) {
		v.build1(Thing)
		|> v.validate(thing.name, name_validator)
	}

	let thing = Thing("1")

	let expected_error = Error(
		tuple(">=3", [">=3", ">=4", ">=5"])
	)

	validator(thing)
	|> should.equal(expected_error)
}

pub fn compose_and_all_test() {
	let name_validator = v_option.is_some("Is null")
		|> v.and(v.all(
				[
					v_string.is_not_empty("Empty"),
					v_string.min_length(">=3", 3),
					v_string.max_length("<=10", 10)
				]
			)
		)

	let validator = fn(thing: InputThing) {
		v.build1(Thing)
		|> v.validate(thing.name, name_validator)
	}

	let thing = InputThing(Some("One Thing after the other"))

	let expected_error = Error(
		tuple("<=10", ["<=10"])
	)

	validator(thing)
	|> should.equal(expected_error)
}

// Validators

pub fn int_min_test() {
	let validator = v_int.min(">=5", 5)

	validator(5)
	|> should.equal(Ok(5))

	let expected_error = Error(tuple(">=5", [">=5"]))

	validator(4)
	|> should.equal(expected_error)
}

pub fn int_max_test() {
	let validator = v_int.max("<=5", 5)

	validator(5)
	|> should.equal(Ok(5))

	let expected_error = Error(tuple("<=5", ["<=5"]))

	validator(6)
	|> should.equal(expected_error)
}

pub fn list_is_not_empty_test() {
	let validator = v_list.is_not_empty("Empty")

	validator([1])
	|> should.equal(Ok([1]))

	let expected_error = Error(tuple("Empty", ["Empty"]))

	validator([])
	|> should.equal(expected_error)
}

pub fn list_min_length_test() {
	let validator = v_list.min_length("Short", 3)

	validator([1,2,3])
	|> should.equal(Ok([1,2,3]))

	let expected_error = Error(tuple("Short", ["Short"]))

	validator([1,2])
	|> should.equal(expected_error)
}

pub fn list_max_length_test() {
	let validator = v_list.max_length("Long", 4)

	validator([1,2,3])
	|> should.equal(Ok([1,2,3]))

	let expected_error = Error(tuple("Long", ["Long"]))

	validator([1,2,3,4,5])
	|> should.equal(expected_error)
}

pub fn list_all_test() {
	let list_validator = v_list.every(
		v_string.min_length("Short", 3)
	)

	let validator = fn(thing: ThingWithList) {
		v.build1(ThingWithList)
		|> v.validate(thing.items, list_validator)
	}

	let thing = ThingWithList(["One", "Two"])

	validator(thing)
	|> should.equal(Ok(thing))

	let thing2 = ThingWithList(["One", "T", "A"])

	let expected_error = Error(
		tuple("Short", ["Short", "Short"])
	)

	validator(thing2)
	|> should.equal(expected_error)
}

pub fn option_is_some_test() {
	let validator = v_option.is_some("Null")

	validator(Some("Hola"))
	|> should.equal(Ok("Hola"))

	let expected_error = Error(tuple("Null", ["Null"]))

	validator(None)
	|> should.equal(expected_error)
}

pub fn string_not_empty_test() {
	let validator = v_string.is_not_empty("Empty")

	validator("One")
	|> should.equal(Ok("One"))

	let expected_error = Error(tuple("Empty", ["Empty"]))

	validator("")
	|> should.equal(expected_error)
}

pub fn string_is_email_test() {
	let validator = v_string.is_email("Not email")

	[
		"a@b",
		"a1@b",
		"a1@b.com",
		"a1@b.com.au",
	] |> list.map(fn(email) {
		validator(email)
		|> should.equal(Ok(email))
	})

	let expected_error = Error(tuple("Not email", ["Not email"]))

	[
		"",
		"a",
		"a@",
		"@b",
	] |> list.map(fn(email) {
		validator(email)
		|> should.equal(expected_error)
	})
}

pub fn string_min_length_test() {
	let validator = v_string.min_length("Less than 3", 3)

	validator("One")
	|> should.equal(Ok("One"))

	let expected_error = Error(tuple("Less than 3", ["Less than 3"]))

	validator("Tw")
	|> should.equal(expected_error)
}

pub fn string_max_length_test() {
	let validator = v_string.max_length("More than 5", 5)

	validator("Hello")
	|> should.equal(Ok("Hello"))

	let expected_error = Error(tuple("More than 5", ["More than 5"]))

	validator("More than five")
	|> should.equal(expected_error)
}