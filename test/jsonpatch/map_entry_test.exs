defmodule Jsonpatch.MapEntryTest do
  use ExUnit.Case
  doctest Jsonpatch.MapEntry

  alias Jsonpatch.MapEntry

  test "convert a one dimensional map to map entries" do
    source = %{"name" => "Bob", "age" => 27}
    map_entries = MapEntry.to_map_entries(source)

    assert %{"/name" => "Bob", "/age" => 27} = map_entries
  end

  test "convert a two dimensional map to map entries" do
    address = %{"city" => "Somewhere", "street" => "Somestreet"}
    source = %{"name" => "Bob", "age" => 27, "address" => address}
    map_entries = MapEntry.to_map_entries(source)

    assert %{
             "/name" => "Bob",
             "/age" => 27,
             "/address/street" => "Somestreet",
             "/address/city" => "Somewhere"
           } = map_entries
  end

  test "convert a four dimensional map to map entries" do
    source = %{"a" => %{"b" => %{"c" => %{"d" => "e"}}}}
    map_entries = MapEntry.to_map_entries(source)

    assert %{"/a/b/c/d" => "e"} = map_entries
  end

  test "convert a two dimensional map with a value array" do
    languages = ["Elixir", "Erlang"]
    source = %{"name" => "Bob", "languages" => languages, "age" => 27}
    map_entries = MapEntry.to_map_entries(source)

    assert %{
             "/name" => "Bob",
             "/languages/1" => "Erlang",
             "/languages/0" => "Elixir",
             "/age" => 27
           } = map_entries
  end

  test "convert a two dimensional map with a map array" do
    employers = [
      %{"name" => "Somecompany1", "city" => "Somewhere"},
      %{"name" => "Othercompany", "city" => "Otherwhere"}
    ]

    source = %{"name" => "Alice", "employers" => employers, "age" => 26}
    map_entries = MapEntry.to_map_entries(source)

    target = %{
      "/name" => "Alice",
      "/employers/1/name" => "Othercompany",
      "/employers/1/city" => "Otherwhere",
      "/employers/0/name" => "Somecompany1",
      "/employers/0/city" => "Somewhere",
      "/age" => 26
    }

    assert ^target = map_entries
  end
end
