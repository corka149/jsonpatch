defmodule Jsonpatch.Operation.TestTest do
  use ExUnit.Case

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
    assert {:ok, ^target} = Test.apply(test_op, target, [])

    test_op = %Test{path: "/a/b/1/c/0", value: 1}
    assert {:ok, ^target} = Test.apply(test_op, target, [])
  end

  test "Test with atom as key" do
    target = %{"role" => "Developer"}

    test_op = %Test{path: "/role", value: "Developer"}

    assert {:ok, ^target} = Test.apply(test_op, target, [])
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

    assert {:error, {:test_failed, "Expected value '42' at '/a/b/1/c/1'"}} =
             Test.apply(test_op, target, [])
  end

  test "Test list with index out of range" do
    test = %Test{path: "/m/2", value: "foo"}
    target = %{"m" => [0, 1]}

    assert {:error, {:invalid_path, ["m", "2"]}} = Test.apply(test, target, [])
  end

  test "Test list with invalid index" do
    test = %Test{path: "/m/b", value: "foo"}
    target = %{"m" => [0, 1]}

    assert {:error, {:invalid_path, ["m", "b"]}} = Test.apply(test, target, [])
  end

  test "Test list at top level" do
    test = %Test{path: "/1", value: "bar"}
    target = ["foo", "bar", "ha"]

    assert {:ok, ^target} = Test.apply(test, target, [])
  end

  test "Test list at top level with error" do
    test = %Test{path: "/2", value: 3}
    target = [0, 1, 2]

    assert {:error, {:test_failed, "Expected value '3' at '/2'"}} = Test.apply(test, target, [])
  end
end
