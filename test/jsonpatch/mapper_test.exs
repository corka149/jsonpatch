defmodule Jsonpatch.MapperTest do
  use ExUnit.Case
  doctest Jsonpatch.Mapper

  describe "Jsonpatch.Mapper.from_map" do
    test "Create add struct from map" do
      patch_map = %{"op" => "add", "path" => "/name", "value" => "Alice"}

      assert %Jsonpatch.Operation.Add{path: "/name", value: "Alice"} =
               Jsonpatch.Mapper.from_map(patch_map)
    end

    test "Create replace struct from map" do
      patch_map = %{"op" => "replace", "path" => "/name", "value" => "Alice"}

      assert %Jsonpatch.Operation.Replace{path: "/name", value: "Alice"} =
               Jsonpatch.Mapper.from_map(patch_map)
    end

    test "Create remove struct from map" do
      patch_map = %{"op" => "remove", "path" => "/name"}
      assert %Jsonpatch.Operation.Remove{path: "/name"} = Jsonpatch.Mapper.from_map(patch_map)
    end

    test "Create copy struct from map" do
      patch_map = %{"op" => "copy", "path" => "/name", "from" => "/surname"}

      assert %Jsonpatch.Operation.Copy{from: "/surname", path: "/name"} =
               Jsonpatch.Mapper.from_map(patch_map)
    end

    test "Create move struct from map" do
      patch_map = %{"op" => "move", "path" => "/name", "from" => "/surname"}

      assert %Jsonpatch.Operation.Move{from: "/surname", path: "/name"} =
               Jsonpatch.Mapper.from_map(patch_map)
    end

    test "Create test struct from map" do
      patch_map = %{"op" => "test", "path" => "/name", "value" => 42}

      assert %Jsonpatch.Operation.Test{value: 42, path: "/name"} =
               Jsonpatch.Mapper.from_map(patch_map)
    end

    test "Create Jsonpatch struct from list" do
      patch_map = %{"op" => "test", "path" => "/name", "value" => 42}

      assert [%Jsonpatch.Operation.Test{value: 42, path: "/name"}] =
               Jsonpatch.Mapper.from_map([patch_map])
    end

    test "Create Jsonpatch struct from invalid map" do
      assert {:error, :invalid} =
               Jsonpatch.Mapper.from_map(%{
                 "op" => "tessstt",
                 "path" => "/name",
                 "value" => "Alice"
               })
    end
  end

  describe "Jsonpatch.Mapper.to_map" do
    test "Create map from add struct" do
      patch_map = %Jsonpatch.Operation.Add{path: "/name", value: "Alice"}

      assert %{op: "add", path: "/name", value: "Alice"} = Jsonpatch.Mapper.to_map(patch_map)
    end

    test "Create map from replace struct" do
      patch_map = %Jsonpatch.Operation.Replace{path: "/name", value: "Alice"}

      assert %{op: "replace", path: "/name", value: "Alice"} = Jsonpatch.Mapper.to_map(patch_map)
    end

    test "Create map from remove struct" do
      patch_map = %Jsonpatch.Operation.Remove{path: "/name"}
      assert %{op: "remove", path: "/name"} = Jsonpatch.Mapper.to_map(patch_map)
    end

    test "Create map from copy struct" do
      patch_map = %Jsonpatch.Operation.Copy{from: "/surname", path: "/name"}

      assert %{from: "/surname", op: "copy", path: "/name"} = Jsonpatch.Mapper.to_map(patch_map)
    end

    test "Create map from move struct" do
      patch_map = %Jsonpatch.Operation.Move{from: "/surname", path: "/name"}

      assert %{from: "/surname", op: "move", path: "/name"} = Jsonpatch.Mapper.to_map(patch_map)
    end

    test "Create map from test struct" do
      patch_map = %Jsonpatch.Operation.Test{value: 42, path: "/name"}

      assert %{op: "test", path: "/name", value: 42} = Jsonpatch.Mapper.to_map(patch_map)
    end

    test "Create list from a list of Jsonpatches" do
      patch_map = %Jsonpatch.Operation.Test{value: 42, path: "/name"}

      assert [%{op: "test", path: "/name", value: 42}] = Jsonpatch.Mapper.to_map([patch_map])
    end

    test "Map invalid paramter list to map and expect no mapping" do
      assert [] = Jsonpatch.Mapper.to_map([%{foo: "bar"}])
    end

    test "Map invalid paramter to map and expect error" do
      assert {:error, :invalid} = Jsonpatch.Mapper.to_map(%{foo: "bar"})
    end
  end
end
