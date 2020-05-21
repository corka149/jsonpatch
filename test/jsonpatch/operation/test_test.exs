defmodule Jsonpatch.Operation.TestTest do
  use ExUnit.Case
  doctest Jsonpatch.Operation.Test

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

    test_op = %Jsonpatch.Operation.Test{path: "/a/b/1/c/2/f", value: false}
    assert :ok = Jsonpatch.Operation.Test.apply_op(test_op, target)

    test_op = %Jsonpatch.Operation.Test{path: "/a/b/1/c/0", value: 1}
    assert :ok = Jsonpatch.Operation.Test.apply_op(test_op, target)
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

    test_op = %Jsonpatch.Operation.Test{path: "/a/b/1/c/1", value: 42}

    patched_target = Jsonpatch.Operation.Test.apply_op(test_op, target)

    assert :error = patched_target
  end
end
