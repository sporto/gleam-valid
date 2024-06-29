# Valid

![CI](https://github.com/sporto/gleam-valid/workflows/test/badge.svg?branch=main)

A validation library for [Gleam](https://gleam.run/).

API Docs: <https://hexdocs.pm/valid>.

This library follows the principle [Parse don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

## Install

```
gleam add valid
```

## Usage

You start with an input type and validate into an output type. These two types can be different. For example:

```gleam
type UserInput { UserInput(name: Option(String), age: Int) }

type ValidUser { ValidUser(name: String, age: Int) }
```

Then you create a validator like:

```gleam
import valid.{type ValidatorResult}

fn user_validator(user: UserInput) -> ValidatorResult(ValidUser, String) {
  valid.build2(ValidUser)
  |> valid.check(user.name, valid.is_some("Please provide a name"))
  |> valid.check(user.age, valid.int_min(13, "Must be at least 13 years old"))
}
```

And run it:

```gleam
case user_valid(input) {
  Ok(valid_user) -> ...
  Error(tuple(first_error, all_errors)) -> ...
}
```

## Error type

Errors can be your own type e.g.

```gleam
import valid.{type ValidatorResult}

type Error {
  ErrorEmptyName,
  ErrorTooYoung,
}

fn user_valid(user: UserInput) -> ValidatorResult(ValidUser, String) {
  valid.build2(ValidUser)
  |> valid.check(user.name, valid.is_some(ErrorEmptyName))
  |> valid.check(user.age, valid.int_min(13, ErrorTooYoung))
}
```

## ValidatorResult

`ValidatorResult(valid, error)` is an alias for `Result(valid, tuple(error, List(error)))`

The `Ok` branch has the valid output.

The `Error` branch has a tuple `tuple(error, List(error))`.

The first value is the first error. The second value is a list with all errors (including the first).

## Validators

See the [API Docs](https://hexdocs.pm/valid/) for the list of included validators.

## Custom property validator

A property validator has two components:

- The error to return
- A function that transforms the property if successful (`fn(input) -> Option(output)`)

Example:

```gleam
import gleam/option.{None, Option, Some}
import valid

fn bigger_than_10(num: Int) -> Option(num) {
  case num > 10 {
    True ->
      Some(num)
    False ->
      None
  }
}

let custom = valid.custom("Must be bigger than 10", bigger_than_10)

let valid = fn(form: FormInput) {
  valid.build1(ValidForm)
  |> valid.check(form.quantity, custom)
}
```

## Validating a Dictionary

Use `required_in_dict` and `optional_in_dict`

```gleam
fn user_validator(dictionary: Dict(String, String)) {
  valid.build2(ValidUser)
  |> valid.check(
    dictionary,
    valid.required_in_dict("name", "Missing name")
      |> valid.and(
        valid.string_is_not_empty("Please provide a name")
      ),
  )
  |> valid.check(
    dictionary,
    valid.optional_in_dict("age")
      |> valid.and_optional(valid.string_is_int("Please provide a valid number")),
  )
}
```

## Examples

See [the tests](https://github.com/sporto/gleam-valid/blob/main/test/valid_test.gleam) for many examples

## TODO

- Move readme examples to gleam code
- Change `whole` to `check_discard`
- Use NonEmpty
- Pass the error to the check
