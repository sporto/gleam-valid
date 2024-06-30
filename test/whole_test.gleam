import gleeunit/should
import valid

type Character {
  Character(level: Int, strength: Int)
}

fn character_validator(c: Character) {
  let whole_validator = fn(c: Character) {
    let error = "Strength cannot be less than level"

    case c.level > c.strength {
      True -> Error(valid.non_empty_new(error, []))
      False -> Ok(c)
    }
  }

  valid.build2(Character)
  |> valid.check(c.level, valid.int_min(1, "Level must be more that zero"))
  |> valid.check(
    c.strength,
    valid.int_min(1, "Strength must be more that zero"),
  )
  |> valid.whole(whole_validator)
}

pub fn whole_test() {
  let char = Character(level: 1, strength: 1)

  character_validator(char)
  |> should.equal(Ok(char))

  let char2 = Character(level: 2, strength: 1)

  character_validator(char2)
  |> should.equal(
    Error(valid.non_empty_new("Strength cannot be less than level", [])),
  )
}
