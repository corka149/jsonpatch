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

    assert :error = patched_target
  end
end
