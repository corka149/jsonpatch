defmodule Jsonpatch.Operation.MoveTest do
  use ExUnit.Case
  doctest Jsonpatch.Operation.Move

  # Basic move operation with atoms
  test "move a value with atoms" do
    move = %Jsonpatch.Operation.Move{from: "/a/b", path: "/a/e"}
    target = %{a: %{b: %{c: "Bob"}}, d: false}

    assert Jsonpatch.Operation.Move.apply(move, target, keys: :atoms) ==
             {:ok, %{a: %{e: %{c: "Bob"}}, d: false}}
  end

  # Move within the same list
  test "move element within the same list" do
    move = %Jsonpatch.Operation.Move{from: "/arr/0", path: "/arr/2"}
    target = %{"arr" => ["a", "b", "c"]}

    assert Jsonpatch.Operation.Move.apply(move, target, []) ==
             {:ok, %{"arr" => ["b", "c", "a"]}}
  end

  # Move to end of list using "-" syntax
  test "move element to end of list using -" do
    move = %Jsonpatch.Operation.Move{from: "/arr/0", path: "/arr/-"}
    target = %{"arr" => ["a", "b", "c"]}

    assert Jsonpatch.Operation.Move.apply(move, target, []) ==
             {:ok, %{"arr" => ["b", "c", "a"]}}
  end

  # Move between different lists
  test "move element between different lists" do
    move = %Jsonpatch.Operation.Move{from: "/arr1/0", path: "/arr2/1"}
    target = %{"arr1" => ["a", "b"], "arr2" => ["x", "y", "z"]}

    assert Jsonpatch.Operation.Move.apply(move, target, []) ==
             {:ok, %{"arr1" => ["b"], "arr2" => ["x", "a", "y", "z"]}}
  end

  # Move from list to object
  test "move element from list to object" do
    move = %Jsonpatch.Operation.Move{from: "/arr/0", path: "/obj/key"}
    target = %{"arr" => ["value"], "obj" => %{"existing" => "data"}}

    assert Jsonpatch.Operation.Move.apply(move, target, []) ==
             {:ok, %{"arr" => [], "obj" => %{"existing" => "data", "key" => "value"}}}
  end

  # Move from object to list
  test "move element from object to list" do
    move = %Jsonpatch.Operation.Move{from: "/obj/key", path: "/arr/0"}
    target = %{"obj" => %{"key" => "value"}, "arr" => ["existing"]}

    assert Jsonpatch.Operation.Move.apply(move, target, []) ==
             {:ok, %{"obj" => %{}, "arr" => ["value", "existing"]}}
  end

  # Move with nested paths
  test "move nested list element" do
    move = %Jsonpatch.Operation.Move{from: "/nested/arr/0", path: "/nested/arr/2"}
    target = %{"nested" => %{"arr" => ["a", "b", "c"]}}

    assert Jsonpatch.Operation.Move.apply(move, target, []) ==
             {:ok, %{"nested" => %{"arr" => ["b", "c", "a"]}}}
  end

  # Edge case: from and path are the same
  test "move when from and path are the same" do
    move = %Jsonpatch.Operation.Move{from: "/arr/0", path: "/arr/0"}
    target = %{"arr" => ["a", "b", "c"]}

    assert Jsonpatch.Operation.Move.apply(move, target, []) ==
             {:ok, %{"arr" => ["a", "b", "c"]}}
  end

  # Error cases
  test "move with invalid source path" do
    move = %Jsonpatch.Operation.Move{from: "/arr/10", path: "/arr/0"}
    target = %{"arr" => ["a", "b", "c"]}

    assert match?(
             {:error, {:invalid_path, ["arr", "10"]}},
             Jsonpatch.Operation.Move.apply(move, target, [])
           )
  end

  test "move with invalid destination path" do
    move = %Jsonpatch.Operation.Move{from: "/arr/0", path: "/arr/10"}
    target = %{"arr" => ["a", "b", "c"]}

    assert match?(
             {:error, {:invalid_path, ["arr", "10"]}},
             Jsonpatch.Operation.Move.apply(move, target, [])
           )
  end
end
