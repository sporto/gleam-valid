# Changelog

### 4.2.0

### Changed

- Email validation accepts `+` and `.` in the suffix

### 4.1.0

### Changed

- Use sub dependency `non_empty_list`

### 4.0.0

### Added

- Type `NonEmptyList`

### Changed

- Renamed `and` to `then`
- Renamed `optional` to `if_some`
- Return errors as `NonEmptyList`
- Type `Check` signature, they should return a `Result(out, error)` now
- Validator builders now take the error as last argument

### Removed

- All `and_` functions, compose using `and` instead
- Type `Error`, replaced with `NonEmptyList`

### 3.0.0

### Changed

- function `validate` renamed to `check`

### Added

- Most checks have an `and_` version. E.g. `and_string_is_int`
- check `ok`
- check `optional_in_dict`
- check `optional_in`
- check `required_in_dict`
- check `required_in`

## 2.0.0

### Changed

- All functions moved to main `valid` module.
- Remove all other sub modules

## 0.2.0

### Changed

- Refactor list.every so it works with nested validators
