# validator

A validation library for Gleam.

This library follows the principal [Parse don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

You start with an input type and validate into an output type. These two types can be different. For example:

```
type InputUser { InputUser(name: Option(String), age: Int) }

type ValidUser { ValidUser(name: String, age: Int) }
```

Then you create a validator like:

```
import validator

fn user_validator(user: UserInput) -> Result(ValidUser, List(String)) {
	validator.build2(ValidUser)
	|> validator.validate(user.name, option.is_some("Please provide a name"))
	|> validator.validate(user.age, number.min(13, "Must be at least 13 years old"))
}
```

And run it:

```
case user_validator(input) {
	Ok(valid_user) -> ...
	Error(errors) -> ...
}
```

## Errors

Errors can be your own type e.g.

```
type Error {
	ErrorEmptyName,
	ErrorTooYoung,
}

fn user_validator(user: UserInput) -> Result(ValidUser, List(String)) {
	validator.build2(ValidUser)
	|> validator.validate(user.name, option.is_some(ErrorEmptyName))
	|> validator.validate(user.age, number.min(13, ErrorTooYoung))
}
```


## Test

```sh
# Build the project
rebar3 compile
```

## TODO

- Compose
- list.is_not_empty
- list.min_length
- list.max_length
- list.every
- number.min
- number.max
- string.is_email
- string.min_length
- string.max_length


## Installation

If [available in Hex](https://www.rebar3.org/docs/dependencies#section-declaring-dependencies)
this package can be installed by adding `validator` to your `rebar.config` dependencies:

```erlang
{deps, [
    validator
]}.
```
