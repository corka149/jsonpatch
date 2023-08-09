# Jsonpatch

![Elixir CI](https://github.com/corka149/jsonpatch/workflows/Elixir%20CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/corka149/jsonpatch/badge.svg?branch=master)](https://coveralls.io/github/corka149/jsonpatch?branch=master)
[![Generic badge](https://img.shields.io/badge/Mutation-Tested-success.svg)](https://shields.io/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/corka149/jsonpatch/graphs/commit-activity)
[![Hex.pm Version](https://img.shields.io/hexpm/v/jsonpatch.svg?style=flat-square)](https://hex.pm/packages/jsonpatch)

An implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.

Features:

- Creating a patch by comparing to maps and lists
- Apply patches to maps and lists - supports operations:
    - add
    - replace
    - remove
    - copy
    - move
    - test
- Escaping of "`/`" (by "`~1`") and "`~`" (by "`~0`")
- Allow usage of `-` for appending things to list (Add and Copy operation)

## Getting started

### Installation

The package can be installed by adding `jsonpatch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jsonpatch, "~> 1.0.1"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/jsonpatch](https://hexdocs.pm/jsonpatch).

### Create a diff

```elixir
iex> source = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"]}
iex> destination = %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
iex> Jsonpatch.diff(source, destination)
[
  %{path: "/married", value: true, op: "replace"},
  %{path: "/hobbies/2", op: "remove"},
  %{path: "/hobbies/1", op: "remove"},
  %{path: "/hobbies/0", value: "Elixir!", op: "replace"},
  %{path: "/age", value: 33, op: "add"}
]
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
