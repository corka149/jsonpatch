defmodule Jsonpatch.PathUtilTest do
  use ExUnit.Case
  doctest Jsonpatch.PathUtil

  alias Jsonpatch.PathUtil

  test "Updated final destination with invalid path and get an error" do
    path = "/a/x/y/z"
    target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}

    assert {:error, :invalid_path, "x"} =
             PathUtil.update_final_destination(target, %{"e" => 1}, path)
  end

  test "Unescape '~' and '/'" do
    assert "unescape~me" = PathUtil.unescape("unescape~0me")
    assert "unescape/me" = PathUtil.unescape("unescape~1me")
    assert "unescape~me/" = PathUtil.unescape("unescape~0me~1")
    assert 1 = PathUtil.unescape(1)
  end
end
