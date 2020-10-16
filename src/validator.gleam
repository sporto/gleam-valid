import gleam/option.{None, Option, Some}
import gleam/result

pub fn not_maybe(
    maybe: Option(a)
  ) -> Result(a, String) {

  case maybe {
    None ->
      Error("Is none")
    Some(a) ->
      Ok(a)
  }
}

pub fn validate(
    accumulator: Result(fn(b) -> next_accumulator, String),
    value: a,
    validator: fn(a) -> Result(b, String)
  ) -> Result(next_accumulator, String) {

  case validator(value) {
    Error(err) ->
      Error(err)

    Ok(value) ->
      accumulator
        |> result.map(
          fn(acc) { acc(value) }
        )
  }
}

pub fn keep(accumulator: Result(fn(a) -> fn2, String), value: a) -> Result(fn2, String) {
  accumulator
  |> result.map(fn(acc) { acc(value) })
}
