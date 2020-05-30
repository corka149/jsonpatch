defmodule Jsonpatch.PathUtilTest do
  use ExUnit.Case
  doctest Jsonpatch.PathUtil

  alias Jsonpatch.PathUtil

  test "Updated final destination with invalid path and get an error" do
    path = "/a/x/y/z"
    target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
    assert {:error, :invalid_path} = PathUtil.update_final_destination(target, %{"e" => 1}, path)
  end
end
