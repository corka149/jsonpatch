defmodule Jsonpatch.MapEntryTest do
  use ExUnit.Case

  alias Jsonpatch.MapEntry

  test "convert a one level map to map entries" do
    source = %{"name" => "Bob", "age" => 27}
    map_entries = MapEntry.to_map_entries(source)

    assert [
      %MapEntry{path: "/name", value: "Bob"},
      %MapEntry{path: "/age", value: 27}
    ] = map_entries
  end

  test "convert a two level map to map entries" do
    address = %{"city" => "Somewhere", "street" => "Somestreet"}
    source = %{"name" => "Bob", "age" => 27, "address" => address}
    map_entries = MapEntry.to_map_entries(source)

    assert [
      %MapEntry{path: "/name", value: "Bob"},
      %MapEntry{path: "/age", value: 27},
      %MapEntry{path: "/address/city", value: "Somewhere"},
      %MapEntry{path: "/address/street", value: "Somestreet"}
    ] = map_entries
  end

end
