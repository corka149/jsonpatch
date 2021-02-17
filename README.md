# Jsonpatch
![Elixir CI](https://github.com/corka149/jsonpatch/workflows/Elixir%20CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/corka149/jsonpatch/badge.svg?branch=master)](https://coveralls.io/github/corka149/jsonpatch?branch=master)
[![Generic badge](https://img.shields.io/badge/Mutation-Tested-success.svg)](https://shields.io/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
[![Hex.pm Version](https://img.shields.io/hexpm/v/jsonpatch.svg?style=flat-square)](https://hex.pm/packages/jsonpatch)

A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.


Features:

1. Creating a patch by comparing to maps and structs
2. Apply patches to maps and structs - supports operations:
    - add
    - replace
    - remove
    - copy
    - move
    - test
3. De/Encoding and mapping
4. Escaping of "`/`" (by "`~1`") and "`~`" (by "`~0`")


## Getting started

### Installation

The package can be installed by adding `jsonpatch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jsonpatch, "~> 0.10.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/jsonpatch](https://hexdocs.pm/jsonpatch).

### Create a diff

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

### Mapping for de- and encoding

Map a JSON patch struct to a regular map.

```elixir
iex> add_patch_map = %Jsonpatch.Operation.Add{path: "/name", value: "Alice"}
iex> Jsonpatch.Mapper.to_map(add_patch_map)
%{op: "add", path: "/name", value: "Alice"}
```

Map a regular map to a JSON patch struct.

```elixir
iex> add_patch_map = %{"op" => "add", "path" => "/name", "value" => "Alice"}
iex> Jsonpatch.Mapper.from_map(add_patch_map)
%Jsonpatch.Operation.Add{path: "/name", value: "Alice"}
```

### Apply patches

```elixir
iex> patch = [
  %Jsonpatch.Operation.Add{path: "/age", value: 33},
  %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
  %Jsonpatch.Operation.Replace{path: "/married", value: true},
  %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
  %Jsonpatch.Operation.Remove{path: "/hobbies/2"}
]
iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"]}
iex> Jsonpatch.apply_patch(patch, target)
{:ok, %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}}
```

## Important sources
- [Official RFC 6902](https://tools.ietf.org/html/rfc6902)
- [Inspiration: python-json-patch](https://github.com/stefankoegl/python-json-patch) 
