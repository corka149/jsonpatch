# Jsonpatch

A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.


Milestones:

- [ ] (primary) Creating a patch
- [ ] (secondary) Apply a patch
- [ ] (maybe) Create manuelly a patch and apply it
- [ ] (maybe) Create patch from Atom and String key mixed structs

## Example

```elixir
iex> source = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"]}
iex> destination = %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
iex> Jsonpatch.diff(source, destination)
[
  %{"op" => "add", "path" => "/age", "value" => 33},
  %{"op" => "replace", "path" => "/married", "value" => True},
  %{"op" => "replace", "path" => "/hobbies/0", "value" => "Elixir!"},
  %{"op" => "remove", "path" => "/hobbies/1"},
  %{"op" => "remove", "path" => "/hobbies/1"}
]
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jsonpatch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jsonpatch, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/jsonpatch](https://hexdocs.pm/jsonpatch).

## Important sources
- [Official RFC 6902](https://tools.ietf.org/html/rfc6902)
- [Inspiration: python-json-patch](https://github.com/stefankoegl/python-json-patch) 

