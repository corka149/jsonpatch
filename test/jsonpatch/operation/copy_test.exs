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

  test "Copy element by path with invalid target index and expect error" do
    from = "/a/b/1/c/2"
    to = "/a/b/1/c/a"

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

    copy_op = %Copy{path: to, from: from}

    patched_target = Operation.apply_op(copy_op, target)

    assert {:error, :invalid_index, "a"} = patched_target
  end

  test "Copy element by path with invalid soure path and expect error" do
    from = "/b"
    to = "/c"

    target = %{
      "a" => 1
    }

    copy_op = %Copy{path: to, from: from}

    patched_target = Operation.apply_op(copy_op, target)

    assert {:error, :invalid_path, "b"} = patched_target
  end

  test "Copy element by path with invalid source index and expect error" do
    from = "/a/b/1/c/b"
    to = "/a/b/1/c/2"

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

    copy_op = %Copy{path: to, from: from}

    patched_target = Operation.apply_op(copy_op, target)

    assert {:error, :invalid_index, "b"} = patched_target
  end
end
