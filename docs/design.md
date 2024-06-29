# Design

## Why not use `use`?

```gleam
use name <- valid.try(name_validator)
use email <- valid.try(email_validator)
```

Looks nice, but the fact that this would short circuit at the first failed validator, means that we cannot collect all errors.

## What if steps in the pipeline imply `and`?

```gleam
let name_validator =
  |> valid.ok
  |> valid.string_is_not_empty("Empty")
  |> valid.string_min_length("More", 6)
  |> valid.string_max_length("Less", 2)
```

This would be nice, as we could get rid of `and`.

Each step in the pipeline would return a function that expected the previous validator.

However `list_all` is an issue.
