# Changelog

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
