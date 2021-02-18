defmodule Jsonpatch.Operation.CopyTest do
  use ExUnit.Case

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Copy

  doctest Copy

  test "Copy element by path with multiple indices" do
    from = "/a/b/1/c/2"
    # Copy to  end
    path = "/a/b/1/c/-"

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

  test "Copy list element" do
    patch = %Copy{from: "/a/0", path: "/a/1"}

    target = %{"a" => [999, 888]}

    patched = Operation.apply_op(patch, target)

    assert %{"a" => [999, 999]} = patched
  end

  test "Copy list element with invalid index" do
    patch = %Copy{from: "/a/0", path: "/a/5"}

    target = %{"a" => [999, 888]}

    patched_error = Operation.apply_op(patch, target)

    assert {:error, :invalid_index, "5"} = patched_error
  end
end
