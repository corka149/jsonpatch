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

  describe "Convert key types" do
    test "With success" do
      assert ["foo", "bar"] = PathUtil.into_key_type(["foo", "bar"], :strings)
      assert [:foo, :bar] = PathUtil.into_key_type(["foo", "bar"], :atoms)
      assert [:foo, "1"] = PathUtil.into_key_type(["foo", "1"], :atoms)
      assert [:foo, :bar] = PathUtil.into_key_type(["foo", "bar"], :atoms!)
      assert [:foo, "1"] = PathUtil.into_key_type(["foo", "1"], :atoms!)
    end

    test "Expect exception when :atoms! was provided but atom does not exist" do
      assert_raise ArgumentError, fn ->
        PathUtil.into_key_type(["does_not_", "exists_as_atom"], :atoms!)
      end
    end

    test "Do not accept unknown key type" do
      assert_raise JsonpatchException, fn ->
        PathUtil.into_key_type(["does not matter"], :not_valid_type)
      end
    end
  end
end
