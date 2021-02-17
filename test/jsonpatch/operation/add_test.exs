defmodule Jsonpatch.Operation.AddTest do
  use ExUnit.Case

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Add

  doctest Add

  test "Added element to path with multiple indices" do
    path = "/a/b/1/c/2/e"

    target = %{
      "a" => %{
        "b" => [
          1,
          %{
            "c" => [
              1,
              2,
              %{"f" => false}
            ]
          }
        ]
      }
    }

    add_op = %Add{path: path, value: true}

    patched_target = Operation.apply_op(add_op, target)

    excpected_target = %{
      "a" => %{
        "b" => [
          1,
          %{
            "c" => [
              1,
              2,
              %{"f" => false, "e" => true}
            ]
          }
        ]
      }
    }

    assert ^excpected_target = patched_target
  end

  test "Add a value to an array" do
    patch = %Add{path: "/a/2", value: 3}
    target = %{"a" => [0, 1, 2]}

    assert %{"a" => [0, 1, 3]} = Operation.apply_op(patch, target)
  end

  test "Add a value to an array with invalid index" do
    patch = %Add{path: "/a/b", value: 3}
    target = %{"a" => [0, 1, 2]}

    assert {:error, :invalid_index, "b"} = Operation.apply_op(patch, target)
  end

  test "Add a value at the end of array" do
    patch = %Add{path: "/a/-", value: 3}
    target = %{"a" => [0, 1, 2]}

    assert %{"a" => [0, 1, 2, 3]} = Operation.apply_op(patch, target)
  end
end
