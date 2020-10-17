import gleam/option.{None, Option, Some}

pub fn is_some(error: e) {
	fn(maybe: Option(a))-> Result(a, List(String)) {
		case maybe {
			None ->
				Error(["Is none"])
			Some(a) ->
				Ok(a)
		}
	}
}