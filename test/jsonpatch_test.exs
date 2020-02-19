defmodule JsonpatchTest do
  use ExUnit.Case

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove

  doctest Jsonpatch

  # ===== ===== kernel functions

  test "create additions" do
    source = %{"/a" => "b"}
    destination = %{"/a" => "b", "/c" => "d"}

    addition_patch = Jsonpatch.create_additions({:ok, []}, source, destination)

    assert {:ok, [%Add{path: "/c", value: "d"}]} = addition_patch
  end

  test "create removes" do
    source = %{"/a" => "b", "/c" => "d"}
    destination = %{"/c" => "d"}

    deletion_patch = Jsonpatch.create_removes({:ok, []}, source, destination)

    assert {:ok, [%Remove{path: "/a"}]} = deletion_patch
  end

  describe "Create diffs" do
    test "adding an Object Member" do
      source = %{"foo" => "bar"}
      destination = %{"foo" => "bar", "baz" => "qux"}

      patch = Jsonpatch.diff(source, destination)

      assert {:ok, [%Add{path: "/baz", value: "qux"}]} = patch
    end

    test "Adding an Array Element" do
      source = %{"foo" => ["bar", "baz"]}
      destination = %{"foo" => ["bar", "baz", "qux"]}

      patch = Jsonpatch.diff(source, destination)

      assert {:ok, [%Add{path: "/foo/2", value: "qux"}]} = patch
    end

    test "Removing an Object Member" do
      source = %{"baz" => "qux", "foo" => "bar"}
      destination = %{ "foo" => "bar" }

      patch = Jsonpatch.diff(source, destination)

      assert {:ok, [%Remove{ path: "/baz" }]} = patch
    end

    test "A.4. Removing an Array Element" do
    end

    test "A.5. Replacing a Value" do
    end

    test "A.6. Moving a Value" do
    end

    test "A.7. Moving an Array Element" do
    end

    test "A.8. Testing a Value: Success" do
    end

    test "A.9. Testing a Value: Error" do
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
  end
end
