import gleam/function
import gleeunit/should
import non_empty_list
import valid

pub fn required_in_test() {
  let validator = valid.required_in(function.identity, "Absent")

  validator(Error(""))
  |> should.equal(Error(non_empty_list.new("Absent", [])))

  validator(Ok(1))
  |> should.equal(Ok(1))
}
