defmodule Jsonpatch.Operation.CopyTest do
  use ExUnit.Case

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Copy

  doctest Copy

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

    copy_op = %Copy{path: path, from: from}

    patched_target = Operation.apply_op(copy_op, target)

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

  test "Copy element by path with invalid index and expect error" do
    path = "/a/b/1/c/a"
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

    copy_op = %Copy{path: path, from: from}

    patched_target = Operation.apply_op(copy_op, target)

    assert {:error, :invalid_index, "a"} = patched_target
  end
end
