import gleam/option.{None, Option, Some}

pub fn is_some(error: e) {
	fn(maybe: Option(a))-> Result(a, List(e)) {
		case maybe {
			None ->
				Error([error])
			Some(a) ->
				Ok(a)
		}
	}
}