defmodule Jsonpatch.PathUtil.ReplaceTest do
  use ExUnit.Case

  alias Jsonpatch.PathUtil.Replace

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

    patched_target = Replace.apply_op(replace_op, target)

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
