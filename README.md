# Jsonpatch
![Elixir CI](https://github.com/corka149/jsonpatch/workflows/Elixir%20CI/badge.svg)

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
{:ok, [
  %Jsonpatch.Operation.Add{path: "/age", value: 33},
  %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
  %Jsonpatch.Operation.Replace{path: "/married", value: true},
  %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
  %Jsonpatch.Operation.Remove{path: "/hobbies/2"}
]}
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

