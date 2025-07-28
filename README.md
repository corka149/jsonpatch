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
- Smart list diffing with `object_hash` for efficient patches on collections with unique identifiers

## Getting started

### Installation

The package can be installed by adding `jsonpatch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jsonpatch, "~> 2.2"}
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

### Smart List Diffing with `object_hash`

Use `object_hash` to generate efficient patches for lists of objects with unique identifiers, producing minimal operations instead of cascading replacements.

```elixir
iex> original = [
  %{id: 1, name: "Alice"},
  %{id: 2, name: "Bob"}
]
iex> updated = [
  %{id: 99, name: "New"},
  %{id: 1, name: "Alice"},
  %{id: 2, name: "Bob"}
]

# Traditional pairwise diff - multiple replace operations
# >> Jsonpatch.diff(original, updated)
[
  %{op: "add", path: "/2", value: %{id: 2, name: "Bob"}}
  %{op: "replace", path: "/0", value: %{id: 99, name: "New"}},
  %{op: "replace", path: "/1", value: %{id: 1, name: "Alice"}},
]

# With object_hash - single add operation
iex> Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
[
  %{op: "add", path: "/0", value: %{id: 99, name: "New"}}
]
```

### Apply patches

```elixir
iex> patch = [
  %{op: "add", path: "/age", value: 33},
  %{op: "replace", path: "/hobbies/0", value: "Elixir!"},
  %{op: "replace", path: "/married", value: true},
  %{op: "remove", path: "/hobbies/1"},
  %{op: "remove", path: "/hobbies/2"}
]
iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"]}
iex> Jsonpatch.apply_patch(patch, target)
{:ok, %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}}
```

## Important sources
- [Official RFC 6902](https://tools.ietf.org/html/rfc6902)
- [Inspiration: python-json-patch](https://github.com/stefankoegl/python-json-patch)
