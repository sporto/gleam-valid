# Valid

![CI](https://github.com/sporto/gleam-valid/workflows/test/badge.svg?branch=main)

A validation library for [Gleam](https://gleam.run/).

API Docs: <https://hexdocs.pm/valid>.

This library follows the principle [Parse don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

```gleam
fn user_validator(user: InputUser) -> ValidatorResult(ValidUser, String) {
  valid.build3(ValidUser)
  |> valid.check(user.name, valid.is_some("Please provide a name"))
  |> valid.check(user.email, valid.is_some("Please provide an email"))
  |> valid.check(user.age, valid.ok())
}

case user_valid(input) {
  Ok(valid_user) -> ...
  Error(errors) -> ...
}
```

## Install

```
gleam add valid
```

## Usage and Examples

- For basic usage see <test/basic_test.gleam>

### Validators

- For string validators, see <test/validator_string_test.gleam>
- For int validators, see <test/validator_int_test.gleam>
- For list validators, see <test/validator_list_test.gleam>
- For optional validators, see <test/validator_option_test.gleam>
- For creating a custom validator, see <test/validator_custom_test.gleam>

### Composition

- For composing validators, see <test/composition_test.gleam>

### Other

- For validating a dictionary, see <test/dictionary_test.gleam>
- For custom error types, see <test/custom_error_test.gleam>
- For validating a whole structure, see <test/whole_test.gleam>
