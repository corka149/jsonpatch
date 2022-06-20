defmodule JsonpatchTest do
  use ExUnit.Case

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace

  doctest Jsonpatch

  test "Create diff from list and apply it" do
    # Arrange
    source = [1, 2, %{"drei" => 3}, 5, 6]
    destination = [1, 2, %{"three" => 3}, 4, 5]

    # Act
    patch = Jsonpatch.diff(source, destination)

    patched_source = Jsonpatch.apply_patch!(patch, source)

    # Assert
    assert ^destination = patched_source
  end

  # ===== DIFF =====
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
               %Jsonpatch.Operation.Remove{
                 path: "/items/0/spec/template/spec/containers/0/ports/0"
               },
               %Jsonpatch.Operation.Replace{
                 path: "/items/0/spec/template/spec/containers/0/image",
                 value: "whoami:1.1.2"
               },
               %Jsonpatch.Operation.Replace{
                 path: "/items/0/spec/template/spec/containers/0/env/0/name",
                 value: "ENVIRONMENT_MESSAGE"
               },
               %Jsonpatch.Operation.Add{
                 path: "/items/0/spec/template/spec/containers/0/env/1",
                 value: %{"name" => "ANOTHER_MESSAGE", "value" => "Hey there!"}
               }
             ] = patch
    end

    test "Create diff with escaped '~' and '/' in path" do
      source = %{}
      destination = %{"escape/me~now" => "somnevalue"}

      actual_patch = Jsonpatch.diff(source, destination)

      assert [%Jsonpatch.Operation.Add{path: "/escape~1me~0now", value: "somnevalue"}] =
               actual_patch
    end

    test "Create diff with nested map with correct Add/Remove order" do
      source = %{"a" => [%{"b" => []}]}
      target = %{"a" => [%{"b" => [%{"c" => 1}, %{"d" => 2}]}]}

      patches = Jsonpatch.diff(source, target)

      assert [
               %Jsonpatch.Operation.Add{path: "/a/0/b/0", value: %{"c" => 1}},
               %Jsonpatch.Operation.Add{path: "/a/0/b/1", value: %{"d" => 2}}
             ] = patches

      source = %{"a" => [%{"b" => [%{"c" => 1}, %{"d" => 2}]}]}
      target = %{"a" => [%{"b" => []}]}

      patches = Jsonpatch.diff(source, target)

      assert [
               %Jsonpatch.Operation.Remove{path: "/a/0/b/1"},
               %Jsonpatch.Operation.Remove{path: "/a/0/b/0"}
             ] = patches
    end

    test "Create diff that replace list with map" do
      source = %{"a" => [1, 2, 3]}
      target = %{"a" => %{"foo" => :bar}}

      patch = Jsonpatch.diff(source, target)
      assert [%Replace{path: "/a", value: %{"foo" => :bar}}] = patch
    end

    test "Create diff when source has a scalar value where in the destination is a list" do
      source = %{"a" => 150}
      destination = %{"a" => [1, 5, 0]}

      patch = Jsonpatch.diff(source, destination)
      assert [%Replace{path: "/a", value: [1, 5, 0]}] = patch
    end

    test "Create diff for lists" do
      source = [1, "pizza", %{"name" => "Alice"}, [4, 2]]
      target = [1, "hamburger", %{"name" => "Alice", "age" => 55}]

      patch = Jsonpatch.diff(source, target)

      assert [
               %Jsonpatch.Operation.Remove{path: "/3"},
               %Jsonpatch.Operation.Add{path: "/2/age", value: 55},
               %Jsonpatch.Operation.Replace{path: "/1", value: "hamburger"}
             ] = patch
    end
  end

  # ===== APPLY =====
  describe "Apply patch/es" do
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
               Jsonpatch.apply_patch(
                 %Jsonpatch.Operation.Replace{path: "/age", value: 42},
                 target
               )

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

    test "Apply patch with multilple operations with binary keys" do
      patch = [
        %Jsonpatch.Operation.Remove{path: "/age"},
        %Jsonpatch.Operation.Add{path: "/age", value: 34},
        %Jsonpatch.Operation.Replace{path: "/age", value: 35}
      ]

      target = %{"age" => "33"}
      patched = Jsonpatch.apply_patch!(patch, target)

      assert %{"age" => 35} = patched
    end

    test "Apply patch with multilple operations with atom keys" do
      patch = [
        %Jsonpatch.Operation.Remove{path: "/age"},
        %Jsonpatch.Operation.Add{path: "/age", value: 34},
        %Jsonpatch.Operation.Replace{path: "/age", value: 35}
      ]

      target = %{age: "33"}
      patched = Jsonpatch.apply_patch!(patch, target, keys: :atoms)

      assert %{age: 35} = patched
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

    test "Apply patch with escaped '~' and '/' in path" do
      patch = [
        %Jsonpatch.Operation.Add{path: "/foo/escape~1me~0now", value: "somnevalue"},
        %Jsonpatch.Operation.Remove{path: "/bar/escape~1me~0now"}
      ]

      target = %{"foo" => %{}, "bar" => %{"escape/me~now" => 5}}

      assert {:ok, %{"foo" => %{"escape/me~now" => "somnevalue"}, "bar" => %{}}} =
               Jsonpatch.apply_patch(patch, target)
    end

    test "Apply patch with '!' and expect valid result" do
      patch = %Jsonpatch.Operation.Remove{path: "/name"}
      target = %{"name" => "Alice", "age" => 44}

      patched = Jsonpatch.apply_patch!(patch, target)
      assert %{"age" => 44} = patched
    end

    test "Apply patch with '!' and expect exception" do
      patch = %Jsonpatch.Operation.Replace{path: "/surname", value: "Misty"}
      target = %{"name" => "Alice", "age" => 44}

      assert_raise JsonpatchException, fn -> Jsonpatch.apply_patch!(patch, target) end
    end
  end
end
