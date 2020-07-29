defmodule Jsonpatch.Operation.ReplaceTest do
  use ExUnit.Case

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Replace

  doctest Replace

  test "Replace element to path with multiple indices" do
    path = "/a/b/1/c/2/f"

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

    replace_op = %Replace{path: path, value: true}

    patched_target = Operation.apply_op(replace_op, target)

    excpected_target = %{
      "a" => %{
        "b" => [
          1,
          %{
            "c" => [
              1,
              2,
              %{"f" => true}
            ]
          }
        ]
      }
    }

    assert ^excpected_target = patched_target
  end

  test "Replace element to path with index out of range and expect error" do
    path = "/a/b/2"

    target = %{
      "a" => %{
        "b" => [
          1
        ]
      }
    }

    replace_op = %Replace{path: path, value: 2}

    patched_target = Operation.apply_op(replace_op, target)

    assert %{"a" => %{"b" => {:error, :invalid_index, "2"}}} = patched_target
  end

  test "Replace element to path with invalid index and expect error" do
    path = "/a/b/c"

    target = %{
      "a" => %{
        "b" => [
          1
        ]
      }
    }

    replace_op = %Replace{path: path, value: 2}

    patched_target = Operation.apply_op(replace_op, target)

    assert %{"a" => %{"b" => {:error, :invalid_index, "c"}}} = patched_target
  end
end
