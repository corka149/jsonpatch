defmodule Jsonpatch.Operation.TestTest do
  use ExUnit.Case

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Test

  doctest Test

  test "Test successful element with path with multiple indices" do
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

    test_op = %Test{path: "/a/b/1/c/2/f", value: false}
    assert ^target = Operation.apply_op(test_op, target)

    test_op = %Test{path: "/a/b/1/c/0", value: 1}
    assert ^target = Operation.apply_op(test_op, target)
  end

  test "Test with atom as key" do
    target = %{role: "Developer"}

    test_op = %Test{path: "/role", value: "Developer"}

    assert ^target = Operation.apply_op(test_op, target, keys: :atoms)
  end

  test "Fail to test element with path with multiple indices" do
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

    test_op = %Test{path: "/a/b/1/c/1", value: 42}

    patched_target = Operation.apply_op(test_op, target)

    assert {:error, :test_failed, "Expected value '42' at '/a/b/1/c/1'"} = patched_target
  end

  test "Test list with index out of range" do
    test = %Test{path: "/m/2", value: "foo"}
    target = %{"m" => [0, 1]}

    assert {:error, :invalid_index, "2"} = Operation.apply_op(test, target)
  end

  test "Test list with invalid index" do
    test = %Test{path: "/m/b", value: "foo"}
    target = %{"m" => [0, 1]}

    assert {:error, :invalid_index, "b"} = Operation.apply_op(test, target)
  end
end
