defmodule Jsonpatch.Operation.CopyTest do
  use ExUnit.Case
  doctest Jsonpatch.Operation.Copy

  test "Copy element by path with multiple indices" do
    path = "/a/b/1/c/3"
    from = "/a/b/1/c/2"

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

    copy_op = %Jsonpatch.Operation.Copy{path: path, from: from}

    patched_target = Jsonpatch.Operation.Copy.apply_op(copy_op, target)

    excpected_target = %{
      "a" => %{
        "b" => [
          1,
          %{
            "c" => [
              1,
              2,
              %{"f" => false},
              %{"f" => false}
            ]
          }
        ]
      }
    }

    assert ^excpected_target = patched_target
  end
end
