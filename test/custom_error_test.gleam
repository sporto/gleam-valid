import gleeunit/should
import non_empty_list
import valid

type User {
  User(name: String)
}

type Error {
  ErrorEmpty
}

fn validator(user: User) {
  valid.build1(User)
  |> valid.check(user.name, valid.string_is_not_empty(ErrorEmpty))
}

pub fn error_type_test() {
  let user = User("")

  let expected_error = Error(non_empty_list.new(ErrorEmpty, []))

  validator(user)
  |> should.equal(expected_error)
}
