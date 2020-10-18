import gleam/string

pub fn is_not_empty(error: e) {
	fn(value: String) {
		case string.is_empty(value) {
			True ->
				Error([error])
			False ->
				Ok(value)
		}
	}
}