defmodule Jsonpatch.OperationTest do
  use ExUnit.Case
  doctest Jsonpatch.Operation

  alias Jsonpatch.Operation

  test "Updated final destination with invalid path and get an error" do
    path = "/a/x/y/z"
    target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
    assert {:error, :invalid_path} = Operation.update_final_destination(target, %{"e" => 1}, path)
  end
end
