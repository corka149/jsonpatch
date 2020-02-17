defmodule JsonpatchTest do
  use ExUnit.Case
  doctest Jsonpatch

  # ===== ===== kernel functions

  test "create additions" do
    source = %{"/a" => "b"}
    destination = %{"/a" => "b", "/c" => "d"}

    addition_patch = Jsonpatch.create_additions([], source, destination)

    assert {:ok, [%{"op" => "add", "path" => "/c", "value" => "d"}]} = addition_patch
  end

  # Use case tests from RFC

  test "A.1. Adding an Object Member" do
    source = %{"foo" => "bar"}
    destination = %{"foo" => "bar", "baz" => "qux"}
    patch = Jsonpatch.diff(source, destination)

    assert {:ok, [%{ "op" => "add", "path" => "/baz", "value" => "qux" }]} = patch
  end

  test "A.2. Adding an Array Element" do

  end

  test "A.3. Removing an Object Member" do

  end

  test "A.4. Removing an Array Element" do

  end

  test "A.5. Replacing a Value" do

  end

  test "A.6. Moving a Value" do

  end

  test "A.7. Moving an Array Element" do

  end

  test "A.8. Testing a Value: Success" do

  end

  test "A.9. Testing a Value: Error" do

  end

  test "A.10. Adding a Nested Member Object" do

  end

  test "A.11. Ignoring Unrecognized Elements" do

  end

  test "A.12. Adding to a Nonexistent Target" do

  end

  test "A.13. Invalid JSON Patch Document" do

  end

  test "A.14. ~ Escape Ordering" do

  end

  test "A.15. Comparing Strings and Numbers" do

  end

  test "A.16. Adding an Array Value" do

  end
end
