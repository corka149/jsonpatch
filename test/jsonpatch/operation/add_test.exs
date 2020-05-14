defmodule Jsonpatch.Operation.AddTest do
  use ExUnit.Case
  doctest Jsonpatch.Operation.Add

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

    add_op = %Jsonpatch.Operation.Add{path: path, value: true}

    patched_target = Jsonpatch.Operation.Add.apply_op(add_op, target)

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
