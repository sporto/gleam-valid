# Valid

![CI](https://github.com/sporto/gleam-valid/workflows/test/badge.svg?branch=main)

A validation library for [Gleam](https://gleam.run/).

API Docs: <https://hexdocs.pm/valid>.

This library follows the principle [Parse don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

The current version (v4) contains two APIs.
The main one using pipelines. And a **experimental** one using `use`.

## API

```gleam
import valid

fn user_validator(input: InputUser) {
  use age <- valid.check(input.age, valid.int_min(13, "Should be at least 13"))
  use name <- valid.check(input.name, valid.string_is_not_empty("Missing name"))
  use email <- valid.check(input.email, valid.string_is_email("Missing email"))

  valid.ok(ValidUser(age:, name:, email:))
}

let input = InputUser(age: 14, name: "Sam", email: "sam@sample.com")

let result = input
 |> valid.validate(user_validator)

 result ==
 Ok(ValidUser(14, "Sam", "sam@sample.com"))
```

### Creating a custom validator

A validator is a function that takes an input, and returns a tuple `#(output, errors)`.

E.g.

```gleam
import valid/experimental as valid

fn is_99(input) {
  case input == 99 {
    True -> #(input, [])
    False -> #(0, ["Not 99"])
  }
}

fn validator(input) {
  use out <- valid.check(input, is_99)
  valid.ok(out)
}
```

A validator must return a default value. This is so we can collect all the errors for all validators (instead of returning early).

### Using own errors

By using your own errors you can add information to link to the source of the issue. e.g.

```gleam

type Field {
  FieldAge
  FieldName
  FieldEmail
}

fn user_validator(input: InputUser) {
  use age <- valid.check(input.age, valid.int_min(13, #(FieldAge,  "Should be at least 13")))
  use name <- valid.check(input.name, valid.string_is_not_empty(#(FieldName, "Missing name")))
  use email <- valid.check(input.email, valid.string_is_email(#(FieldEmail, "Missing email")))

  valid.ok(ValidUser(age:, name:, email:))
}
```
