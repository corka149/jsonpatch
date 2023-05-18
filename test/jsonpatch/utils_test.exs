defmodule Jsonpatch.UtilsTest do
  use ExUnit.Case
  doctest Jsonpatch.Utils

  alias Jsonpatch.Utils

  test "Updated destination with invalid path and get an error" do
    path = "/a/x/y/z"
    target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}

    assert {:error, {:invalid_path, ["a", "x"]}} =
             Utils.update_destination(target, %{"e" => 1}, path)
  end

  test "Unescape '~' and '/'" do
    assert "unescape~me" = Utils.unescape("unescape~0me")
    assert "unescape/me" = Utils.unescape("unescape~1me")
    assert "unescape~me/" = Utils.unescape("unescape~0me~1")
  end
end
