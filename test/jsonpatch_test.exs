defmodule JsonpatchTest do
  use ExUnit.Case

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace

  doctest Jsonpatch

  # ===== ===== kernel functions

  test "create additions" do
    source = %{"/a" => "b"}
    destination = %{"/a" => "b", "/c" => "d"}

    addition_patch = Jsonpatch.create_additions(source, destination)

    assert [%Add{path: "/c", value: "d"}] = addition_patch
  end

  test "create removes" do
    source = %{"/a" => "b", "/c" => "d"}
    destination = %{"/c" => "d"}

    deletion_patch = Jsonpatch.create_removes(source, destination)

    assert [%Remove{path: "/a"}] = deletion_patch
  end

  test "create replaces" do
    source = %{"/a" => "b", "/c" => "d"}
    destination = %{"/a" => "f", "/c" => "d"}

    replace_patch = Jsonpatch.create_replaces(source, destination)

    assert [%Replace{path: "/a", value: "f"}] = replace_patch
  end

  describe "Create diffs" do
    test "adding an Object Member" do
      source = %{"foo" => "bar"}
      destination = %{"foo" => "bar", "baz" => "qux"}

      patch = Jsonpatch.diff(source, destination)

      assert [%Add{path: "/baz", value: "qux"}] = patch
    end

    test "Adding an Array Element" do
      source = %{"foo" => ["bar", "baz"]}
      destination = %{"foo" => ["bar", "baz", "qux"]}

      patch = Jsonpatch.diff(source, destination)

      assert [%Add{path: "/foo/2", value: "qux"}] = patch
    end

    test "Removing an Object Member" do
      source = %{"baz" => "qux", "foo" => "bar"}
      destination = %{"foo" => "bar"}

      patch = Jsonpatch.diff(source, destination)

      assert [%Remove{path: "/baz"}] = patch
    end

    test "A.4. Removing an Array Element" do
      source = %{"a" => %{"b" => ["c", "d"]}}
      destination = %{"a" => %{"b" => ["c"]}}

      patch = Jsonpatch.diff(source, destination)

      assert [%Remove{path: "/a/b/1"}] = patch
    end

    test "Replacing a Value" do
      source = %{"a" => %{"b" => %{"c" => "d"}}, "f" => "g"}
      destination = %{"a" => %{"b" => %{"c" => "h"}}, "f" => "g"}

      patch = Jsonpatch.diff(source, destination)

      assert [%Replace{path: "/a/b/c", value: "h"}] = patch
    end

    test "Replacing an Array Element" do
      source = %{"a" => %{"b" => %{"c" => ["d1", "d2"]}}, "f" => "g"}
      destination = %{"a" => %{"b" => %{"c" => ["d1", "d3"]}}, "f" => "g"}

      patch = Jsonpatch.diff(source, destination)

      assert [%Replace{path: "/a/b/c/1", value: "d3"}] = patch
    end

    test "Create diff for a Kubernetes deployment" do
      source =
        File.read!("test/jsonpatch/res/deploy_source.json")
        |> Poison.Parser.parse!(%{})

      destination =
        File.read!("test/jsonpatch/res/deploy_destination.json")
        |> Poison.Parser.parse!(%{})

      patch = Jsonpatch.diff(source, destination)

      assert [
               %Jsonpatch.Operation.Add{
                 path: "/items/0/spec/template/spec/containers/0/env/1/value",
                 value: "Hey there!"
               },
               %Jsonpatch.Operation.Add{
                 path: "/items/0/spec/template/spec/containers/0/env/1/name",
                 value: "ANOTHER_MESSAGE"
               },
               %Jsonpatch.Operation.Replace{
                 path: "/items/0/spec/template/spec/containers/0/env/0/name",
                 value: "ENVIRONMENT_MESSAGE"
               },
               %Jsonpatch.Operation.Replace{
                 path: "/items/0/spec/template/spec/containers/0/image",
                 value: "whoami:1.1.2"
               },
               %Jsonpatch.Operation.Remove{
                 path: "/items/0/spec/template/spec/containers/0/ports/0/protocol"
               },
               %Jsonpatch.Operation.Remove{
                 path: "/items/0/spec/template/spec/containers/0/ports/0/containerPort"
               }
             ] = patch
    end
  end

  test "Apply patch with invalid source path and expect error" do
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    assert {:error, :invalid_path, "child"} =
             Jsonpatch.apply_patch(
               %Jsonpatch.Operation.Add{path: "/child/0/age", value: 33},
               target
             )

    assert {:error, :invalid_path, "age"} =
             Jsonpatch.apply_patch(%Jsonpatch.Operation.Replace{path: "/age", value: 42}, target)

    assert {:error, :invalid_path, "hobby"} =
             Jsonpatch.apply_patch(%Jsonpatch.Operation.Remove{path: "/hobby/4"}, target)

    assert {:error, :invalid_path, "nameX"} =
             Jsonpatch.apply_patch(
               %Jsonpatch.Operation.Copy{from: "/nameX", path: "/surname"},
               target
             )

    assert {:error, :invalid_path, "homeX"} =
             Jsonpatch.apply_patch(
               %Jsonpatch.Operation.Move{from: "/homeX", path: "/work"},
               target
             )
  end

  test "Apply patch with invalid target source path and expect error" do
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    assert {:error, :invalid_path, "xyz"} =
             Jsonpatch.apply_patch(
               %Jsonpatch.Operation.Copy{from: "/name", path: "/xyz/surname"},
               target
             )

    assert {:error, :invalid_path, "xyz"} =
             Jsonpatch.apply_patch(
               %Jsonpatch.Operation.Move{from: "/home", path: "/xyz/work"},
               target
             )

    assert {:error, :invalid_path, "xyz"} =
             Jsonpatch.apply_patch(
               %Jsonpatch.Operation.Remove{path: "/xyz/work"},
               target
             )
  end

  test "Apply patch with one invalid path and expect error" do
    patch = [
      %Jsonpatch.Operation.Add{path: "/age", value: 33},
      %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
      %Jsonpatch.Operation.Replace{path: "/married", value: true},
      %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
      # Should fail
      %Jsonpatch.Operation.Remove{path: "/hobbies/4"},
      %Jsonpatch.Operation.Copy{from: "/name", path: "/surname"},
      %Jsonpatch.Operation.Move{from: "/home", path: "/work"},
      %Jsonpatch.Operation.Test{path: "/name", value: "Bob"}
    ]

    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    assert {:error, :invalid_index, "4"} = Jsonpatch.apply_patch(patch, target)
  end

  test "Apply patch with failing test and expect error" do
    patch = [
      %Jsonpatch.Operation.Add{path: "/age", value: 33},
      %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
      %Jsonpatch.Operation.Replace{path: "/married", value: true},
      %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
      %Jsonpatch.Operation.Copy{from: "/name", path: "/surname"},
      %Jsonpatch.Operation.Move{from: "/home", path: "/work"},
      # Name is Bob therefore this should fail
      %Jsonpatch.Operation.Test{path: "/name", value: "Alice"},
      # Should never be applied
      %Jsonpatch.Operation.Test{path: "/year", value: 1980}
    ]

    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    assert {:error, :test_failed, "Expected value 'Alice' at '/name'"} =
             Jsonpatch.apply_patch(patch, target)
  end
end
