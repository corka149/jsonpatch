
check:
	mix format
	mix test
	mix dialyzer
	mix credo --strict
	mix muzak
