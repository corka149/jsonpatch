defmodule Jsonpatch.Operation.AddTest do
  use ExUnit.Case

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

    expected_target = %{
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

    assert {:ok, ^expected_target} = Jsonpatch.Operation.Add.apply(add_op, target, [])
  end

  test "Add a value on an existing path" do
    patch = %Add{path: "/a/b", value: 2}
    target = %{"a" => %{"b" => 1}}

    assert {:ok, %{"a" => %{"b" => 2}}} = Jsonpatch.Operation.Add.apply(patch, target, [])
  end

  test "Add a value to an array" do
    patch = %Add{path: "/a/2", value: 2}
    target = %{"a" => [0, 1, 3]}

    assert {:ok, %{"a" => [0, 1, 2, 3]}} = Jsonpatch.Operation.Add.apply(patch, target, [])
  end

  test "Add a value to an empty array with binary key" do
    patch = %Add{path: "/a/0", value: 3}
    target = %{"a" => []}

    assert {:ok, %{"a" => [3]}} = Jsonpatch.Operation.Add.apply(patch, target, [])
  end

  test "Add a value to an empty array with atom key" do
    patch = %Add{path: "/a/0", value: 3}
    target = %{"a" => []}

    assert {:ok, %{"a" => [3]}} = Jsonpatch.Operation.Add.apply(patch, target, [])
  end

  test "Add a value to an array with invalid index" do
    patch = %Add{path: "/a/100", value: 3}
    target = %{"a" => [0, 1, 2]}

    assert {:error, {:invalid_path, ["a", "100"]}} =
             Jsonpatch.Operation.Add.apply(patch, target, [])

    patch = %Add{path: "/a/not_an_index", value: 3}

    assert {:error, {:invalid_path, ["a", "not_an_index"]}} =
             Jsonpatch.Operation.Add.apply(patch, target, [])
  end

  test "Add a value at the end of array" do
    patch = %Add{path: "/a/-", value: 3}
    target = %{"a" => [0, 1, 2]}

    assert {:ok, %{"a" => [0, 1, 2, 3]}} = Jsonpatch.Operation.Add.apply(patch, target, [])

    patch = %Add{path: "/a/#{length(target["a"])}", value: 3}

    assert {:ok, %{"a" => [0, 1, 2, 3]}} = Jsonpatch.Operation.Add.apply(patch, target, [])
  end
end
