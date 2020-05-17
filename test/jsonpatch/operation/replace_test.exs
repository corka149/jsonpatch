defmodule Jsonpatch.Operation.ReplaceTest do
  use ExUnit.Case
  doctest Jsonpatch.Operation.Replace

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

    replace_op = %Jsonpatch.Operation.Replace{path: path, value: true}

    patched_target = Jsonpatch.Operation.Replace.apply_op(replace_op, target)

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
end
