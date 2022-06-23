defmodule RemoveTest do
  use ExUnit.Case

  alias Jsonpatch.Operation
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

    patched_target = Operation.apply_op(remove_op, target)

    excpected_target = %{
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

    assert ^excpected_target = patched_target
  end

  test "Remove element by invalid path" do
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    remove_patch = %Remove{path: "/nameX"}
    assert {:error, :invalid_path, "nameX"} = Operation.apply_op(remove_patch, target)
  end

  test "Remove element in map with atom keys" do
    target = %{name: "Ceasar", age: 66}

    remove_patch = %Remove{path: "/age"}

    assert %{name: "Ceasar"} = Operation.apply_op(remove_patch, target, keys: :atoms)
  end

  test "Remove element by invalid index" do
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => ["Sport", "Elixir", "Football"],
      "home" => "Berlin"
    }

    remove_patch = %Remove{path: "/hobbies/a"}
    assert {:error, :invalid_index, "a"} = Operation.apply_op(remove_patch, target)

    # Longer path
    target = %{
      "name" => "Bob",
      "married" => false,
      "hobbies" => [%{"description" => "Foo"}],
      "home" => "Berlin"
    }

    remove_patch = %Remove{path: "/hobbies/b/description"}
    assert {:error, :invalid_index, "b"} = Operation.apply_op(remove_patch, target)

    # Longer path, numeric - out of
    remove_patch = %Remove{path: "/hobbies/1/description"}
    assert {:error, :invalid_index, 1} = Operation.apply_op(remove_patch, target)
  end

  test "Return error when patch error was provided to remove operation" do
    patch = %Remove{path: "/a"}
    error = {:error, :invalid_index, "4"}

    assert ^error = Operation.apply_op(patch, error)
  end

  test "Remove in list" do
    # Arrange
    source = [1, 2, %{"three" => 3}, 5, 6]
    patch = %Remove{path: "/2/three"}

    # Act
    patched_source = Operation.apply_op(patch, source)

    # Assert
    assert [1, 2, %{}, 5, 6] = patched_source
  end

  test "Remove in list with wrong key" do
    # Arrange
    source = [1, 2, %{"three" => 3}, 5, 6]
    patch = %Remove{path: "/2/four"}

    # Act
    patched_source = Operation.apply_op(patch, source)

    # Assert
    assert {:error, :invalid_path, "four"} = patched_source
  end
end
