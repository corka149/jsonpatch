defmodule Jsonpatch.Operation.CopyTest do
  use ExUnit.Case

  alias Jsonpatch.Operation.Copy

  doctest Copy

  test "Copy element by path with multiple indices" do
    from = "/a/b/1/c/2"
    # Copy to end
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

    expected_target = %{
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

    assert {:ok, ^expected_target} = Jsonpatch.Operation.Copy.apply(copy_op, target, [])
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

    assert {:error, {:invalid_path, ["a", "b", "1", "c", "a"]}} =
             Jsonpatch.Operation.Copy.apply(copy_op, target, [])
  end

  test "Copy element by path with invalid soure path and expect error" do
    from = "/b"
    to = "/c"

    target = %{
      "a" => 1
    }

    copy_op = %Copy{path: to, from: from}

    assert {:error, {:invalid_path, ["b"]}} = Jsonpatch.Operation.Copy.apply(copy_op, target, [])
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

    assert {:error, {:invalid_path, ["a", "b", "1", "c", "b"]}} =
             Jsonpatch.Operation.Copy.apply(copy_op, target, [])
  end

  test "Copy list element" do
    patch = %Copy{from: "/a/0", path: "/a/1"}

    target = %{"a" => [999, 888]}

    assert {:ok, %{"a" => [999, 999, 888]}} = Jsonpatch.Operation.Copy.apply(patch, target, [])
  end

  test "Copy list element from invalid index" do
    patch = %Copy{from: "/a/6", path: "/a/0"}

    target = %{"a" => [999, 888]}

    assert {:error, {:invalid_path, ["a", "6"]}} =
             Jsonpatch.Operation.Copy.apply(patch, target, [])

    patch = %Copy{from: "/a/-", path: "/a/0"}

    assert {:error, {:invalid_path, ["a", "-"]}} =
             Jsonpatch.Operation.Copy.apply(patch, target, [])
  end

  test "Copy list element to invalid index" do
    patch = %Copy{from: "/a/0", path: "/a/5"}

    target = %{"a" => [999, 888]}

    assert {:error, {:invalid_path, ["a", "5"]}} =
             Jsonpatch.Operation.Copy.apply(patch, target, [])
  end
end
