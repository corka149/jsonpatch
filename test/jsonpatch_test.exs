defmodule JsonpatchTest do
  use ExUnit.Case

  alias Jsonpatch.PathUtil.Add
  alias Jsonpatch.PathUtil.Remove
  alias Jsonpatch.PathUtil.Replace

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

    test "A.10. Adding a Nested Member Object" do
    end

    test "A.11. Ignoring Unrecognized Elements" do
    end

    test "A.12. Adding to a Nonexistent Target" do
    end

    test "A.13. Invalid JSON Patch Document" do
    end

    test "A.14. ~ Escape Ordering" do
    end

    test "A.15. Comparing Strings and Numbers" do
    end

    test "A.16. Adding an Array Value" do
    end

    test "Create diff for a Kubernetes deployment" do
      source =
        File.read!("test/jsonpatch/res/deploy_source.json")
        |> Poison.Parser.parse!()

      destination =
        File.read!("test/jsonpatch/res/deploy_destination.json")
        |> Poison.Parser.parse!()

      patch = Jsonpatch.diff(source, destination)

      assert [
               %Jsonpatch.PathUtil.Add{
                 path: "/items/0/spec/template/spec/containers/0/env/1/value",
                 value: "Hey there!"
               },
               %Jsonpatch.PathUtil.Add{
                 path: "/items/0/spec/template/spec/containers/0/env/1/name",
                 value: "ANOTHER_MESSAGE"
               },
               %Jsonpatch.PathUtil.Replace{
                 path: "/items/0/spec/template/spec/containers/0/env/0/name",
                 value: "ENVIRONMENT_MESSAGE"
               },
               %Jsonpatch.PathUtil.Replace{
                 path: "/items/0/spec/template/spec/containers/0/image",
                 value: "whoami:1.1.2"
               },
               %Jsonpatch.PathUtil.Remove{
                 path: "/items/0/spec/template/spec/containers/0/ports/0/protocol"
               },
               %Jsonpatch.PathUtil.Remove{
                 path: "/items/0/spec/template/spec/containers/0/ports/0/containerPort"
               }
             ] = patch
    end
  end

  test "Apply patch with invalid source path and expect no target change" do
    patch = [
      %Jsonpatch.PathUtil.Add{path: "/child/0/age", value: 33},
      %Jsonpatch.PathUtil.Replace{path: "/age", value: 42},
      %Jsonpatch.PathUtil.Remove{path: "/hobby/4"},
      %Jsonpatch.PathUtil.Copy{from: "/nameX", path: "/surname"},
      %Jsonpatch.PathUtil.Move{from: "/homeX", path: "/work"}
    ]

    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    for singe_patch <- patch do
      assert ^target = Jsonpatch.apply_patch(singe_patch, target)
    end
  end

  test "Apply patch with invalid target source path and expect no target change" do
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    assert ^target =
             Jsonpatch.apply_patch(
               %Jsonpatch.PathUtil.Copy{from: "/name", path: "/xyz/surname"},
               target
             )

    assert ^target =
             Jsonpatch.apply_patch(
               %Jsonpatch.PathUtil.Move{from: "/home", path: "/xyz/work"},
               target
             )

    assert ^target =
             Jsonpatch.apply_patch(
               %Jsonpatch.PathUtil.Remove{path: "/xyz/work"},
               target
             )
  end

  test "Apply patch with one invalid path and expect no target change" do
    patch = [
      %Jsonpatch.PathUtil.Add{path: "/age", value: 33},
      %Jsonpatch.PathUtil.Replace{path: "/hobbies/0", value: "Elixir!"},
      %Jsonpatch.PathUtil.Replace{path: "/married", value: true},
      %Jsonpatch.PathUtil.Remove{path: "/hobbies/1"},
      # Should fail
      %Jsonpatch.PathUtil.Remove{path: "/hobbies/4"},
      %Jsonpatch.PathUtil.Copy{from: "/name", path: "/surname"},
      %Jsonpatch.PathUtil.Move{from: "/home", path: "/work"},
      %Jsonpatch.PathUtil.Test{path: "/name", value: "Bob"}
    ]

    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    assert ^target = Jsonpatch.apply_patch(patch, target)
  end
end
