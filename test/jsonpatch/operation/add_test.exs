defmodule Jsonpatch.PathUtil.AddTest do
  use ExUnit.Case

  alias Jsonpatch.PathUtil.Add

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

    patched_target = Add.apply_op(add_op, target)

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
end
