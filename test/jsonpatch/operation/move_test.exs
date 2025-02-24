defmodule Jsonpatch.Operation.MoveTest do
  use ExUnit.Case
  doctest Jsonpatch.Operation.Move

  # Move is a combination of the copy and remove operation.
  test "move a value with atoms" do
    move = %Jsonpatch.Operation.Move{from: "/a/b", path: "/a/e"}
    target = %{a: %{b: %{c: "Bob"}}, d: false}

    assert Jsonpatch.Operation.Move.apply(move, target, keys: :atoms) ==
             {:ok, %{a: %{e: %{c: "Bob"}}, d: false}}
  end
end
