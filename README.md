# Jsonpatch
![Elixir CI](https://github.com/corka149/jsonpatch/workflows/Elixir%20CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/corka149/jsonpatch/badge.svg?branch=master)](https://coveralls.io/github/corka149/jsonpatch?branch=master)

A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.


Milestones:

- [x] (primary) Creating a patch
- [x] De/serialize patches
- [x] (secondary) Apply a patch
- [ ] Create a plug

## Usage

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

### Encode and decode

Encode a JSON patch struct to JSON string.

```elixir
iex> Jsonpatch.Coder.decode("{\"op\": \"add\",\"value\": \"1\",\"path\": \"/age\"}")
{:ok, %Jsonpatch.Operation.Add{path: "/age", value: 1}}
```

Decode a JSON patch struct from a JSON string.

```elixir
iex> Jsonpatch.Coder.encode(%Jsonpatch.Operation.Add{path: "/age", value: 1})
{:ok, "{\"op\": \"add\",\"value\": \"1\",\"path\": \"/age\"}"}
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
%{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
```

## Operations

Some operations are supported, some not.

### Supported

Available for objects and arrays
- Add
- Remove
- Replace

### Unsupported

- Test: Soon
- Move: Soon
- Copy: Soon

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jsonpatch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jsonpatch, "~> 0.3.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/jsonpatch](https://hexdocs.pm/jsonpatch).

## Important sources
- [Official RFC 6902](https://tools.ietf.org/html/rfc6902)
- [Inspiration: python-json-patch](https://github.com/stefankoegl/python-json-patch) 
