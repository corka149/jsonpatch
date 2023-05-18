defmodule Jsonpatch.Operation.ReplaceTest do
  use ExUnit.Case

  alias Jsonpatch.Operation.Replace

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

    expected_target = %{
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

    assert {:ok, ^expected_target} = Replace.apply(replace_op, target, [])
  end

  test "Replace element to path with index out of range and expect error" do
    path = "/a/b/2"

    target = %{
      "a" => %{
        "b" => [
          1
        ]
      }
    }

    replace_op = %Replace{path: path, value: 2}

    assert {:error, {:invalid_path, ["a", "b", "2"]}} = Replace.apply(replace_op, target, [])
  end

  test "Replace element to path with invalid index and expect error" do
    path = "/a/b/c"

    target = %{
      "a" => %{
        "b" => [
          1
        ]
      }
    }

    replace_op = %Replace{path: path, value: 2}

    assert {:error, {:invalid_path, ["a", "b", "c"]}} = Replace.apply(replace_op, target, [])
  end

  test "Replace in not existing path" do
    path = "/a/b/c"

    target = %{
      "a" => %{
        "b" => 1
      }
    }

    replace_op = %Replace{path: path, value: 2}

    assert {:error, {:invalid_path, ["a", "b", "c"]}} = Replace.apply(replace_op, target, [])
  end
end
