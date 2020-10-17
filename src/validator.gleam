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

pub fn map2(constructor: fn(a, b) -> value) {
  fn(a) {
    fn(b) {
        constructor(a, b)
    }
  }
}

pub fn map3(constructor: fn(a, b, c) -> value) {
  fn(a) {
    fn(b) {
      fn(c) {
        constructor(a, b, c)
      }
    }
  }
}

pub fn map4(constructor: fn(a, b, c, d) -> value) {
  fn(a) {
    fn(b) {
      fn(c) {
        fn(d) {
          constructor(a, b, c, d)
        }
      }
    }
  }
}

pub fn map5(constructor: fn(a, b, c, d, e) -> value) {
  fn(a) {
    fn(b) {
      fn(c) {
        fn(d) {
          fn(e) {
            constructor(a, b, c, d, e)
          }
        }
      }
    }
  }
}

pub fn map6(constructor: fn(a, b, c, d, e, f) -> value) {
  fn(a) {
    fn(b) {
      fn(c) {
        fn(d) {
          fn(e) {
            fn(f) {
                constructor(a, b, c, d, e, f)
            }
          }
        }
      }
    }
  }
}