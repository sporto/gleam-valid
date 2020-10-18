import gleam/option.{None, Option, Some}
import gleam/function
import validator/common

pub fn is_some(error: e) {
  common.custom_validator(error, function.identity)
}
