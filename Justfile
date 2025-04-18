changelog:
  git cliff --output CHANGELOG.md

test:
	gleam test

docs:
	gleam docs build

publish:
	gleam publish
