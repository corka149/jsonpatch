defmodule RemoveTest do
  use ExUnit.Case

  alias Jsonpatch.Operation.Remove

  doctest Remove

  test "Remove element by path with multiple indices" do
    path = "/a/b/1/c/2"

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

    remove_op = %Remove{path: path}

    expected_target = %{
      "a" => %{
        "b" => [
          1,
          %{
            "c" => [
              1,
              2
            ]
          }
        ]
      }
    }

    assert {:ok, ^expected_target} = Jsonpatch.Operation.Remove.apply(remove_op, target, [])
  end

  test "Remove element by invalid path" do
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    remove_patch = %Remove{path: "/nameX"}

    assert {:error, {:invalid_path, ["nameX"]}} =
             Jsonpatch.Operation.Remove.apply(remove_patch, target, [])

    remove_patch = %Remove{path: "/home/nameX"}

    assert {:error, {:invalid_path, ["home", "nameX"]}} =
             Jsonpatch.Operation.Remove.apply(remove_patch, target, [])
  end

  test "Remove element in map with atom keys" do
    target = %{"name" => "Ceasar", "age" => 66}

    remove_patch = %Remove{path: "/age"}

    assert {:ok, %{"name" => "Ceasar"}} =
             Jsonpatch.Operation.Remove.apply(remove_patch, target, [])
  end

  test "Remove element by invalid index" do
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    remove_patch = %Remove{path: "/hobbies/a"}

    assert {:error, {:invalid_path, ["hobbies", "a"]}} =
             Jsonpatch.Operation.Remove.apply(remove_patch, target, [])

    # Longer path
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => [%{"description" => "Foo"}],
      "home" => "Berlin"
    }

    remove_patch = %Remove{path: "/hobbies/b/description"}

    assert {:error, {:invalid_path, ["hobbies", "b"]}} =
             Jsonpatch.Operation.Remove.apply(remove_patch, target, [])

    # Longer path, numeric - out of
    remove_patch = %Remove{path: "/hobbies/1/description"}

    assert {:error, {:invalid_path, ["hobbies", "1"]}} =
             Jsonpatch.Operation.Remove.apply(remove_patch, target, [])

    remove_patch = %Remove{path: "/hobbies/-"}

    assert {:error, {:invalid_path, ["hobbies", "-"]}} =
             Jsonpatch.Operation.Remove.apply(remove_patch, target, [])
  end

  test "Remove in list" do
    source = [1, 2, %{"three" => 3}, 5, 6]
    patch = %Remove{path: "/2/three"}

    assert {:ok, [1, 2, %{}, 5, 6]} = Jsonpatch.Operation.Remove.apply(patch, source, [])
  end

  test "Remove in list with wrong key" do
    source = [1, 2, %{"three" => 3}, 5, 6]
    patch = %Remove{path: "/2/four"}

    assert {:error, {:invalid_path, ["2", "four"]}} =
             Jsonpatch.Operation.Remove.apply(patch, source, [])
  end
end
