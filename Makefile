.PHONY: check


check:
	mix format --check-formatted
	mix test
	mix dialyzer
	mix credo --strict
	MIX_ENV=test mix coveralls
