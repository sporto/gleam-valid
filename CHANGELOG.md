# Changelog

## 5.2.0 - 2026-08-05

### Added

- Added check `is_ok`

## 5.1.1 - 2026-05-22

### Changed

- Allow using Gleam standard library v1

## 5.1.0 - 2025-10-12

### Added

- Add string_is_bool
- Add string_matches_regex

## 5.0.0 - 2025-05-14

### Changed

- [**breaking**] Move to 'use' API
This release removes the previous pipeline api, in favour
of `use`.

## 4.5.0 - 2025-04-18

### Added

- Add `all` validator

## 4.4.0 - 2025-04-18

### Added

- Add experimental api using use

## 4.2.1 - 2024-10-04

### Fixed

- Email contain with multiple char in prefix/suffix

## 4.2.0 - 2024-09-22

### Changed

- Allow . to separate firstname and lastname in email format

## 4.1.0

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
