test:
	rebar3 eunit

docs:
	gleam docs build

docs-preview:
	sfz -r ./gen/docs/