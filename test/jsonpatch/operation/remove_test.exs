defmodule Jsonpatch.Operation.RemoveTest do
  use ExUnit.Case

  alias Jsonpatch.Operation.Remove

  doctest Remove

  test "Remove element by path with multiple indices" do
    path = "/a/b/1/c/2"

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

    remove_op = %Remove{path: path}

    patched_target = Remove.apply_op(remove_op, target)

    excpected_target = %{
      "a" => %{
        "b" => [
          1,
          %{
            "c" => [
              1,
              2
            ]
          }
        ]
      }
    }

    assert ^excpected_target = patched_target
  end
end
