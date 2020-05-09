defmodule Jsonpatch.CoderTest do
  use ExUnit.Case

  test "encode list of JSON patches" do
    patch = [
      %Jsonpatch.Operation.Add{path: "/age", value: 1},
      %Jsonpatch.Operation.Remove{path: "/age"},
      %Jsonpatch.Operation.Replace{path: "/name", value: "Bob"}
    ]

    json_patch = Jsonpatch.Coder.encode(patch)

    expected_json_patch_str = "[{\"op\":\"add\",\"value\":1,\"path\":\"/age\"}"
    expected_json_patch_str = expected_json_patch_str <> ",{\"op\":\"remove\",\"path\":\"/age\"},"
    expected_json_patch_str =
      expected_json_patch_str <> "{\"op\":\"replace\",\"value\":\"Bob\",\"path\":\"/name\"}]"

    assert {:ok, ^expected_json_patch_str} = json_patch
  end

  test "encode single operations" do
    add_patch = %Jsonpatch.Operation.Add{path: "/age", value: 1}
    assert {:ok, "{\"op\":\"add\",\"value\":1,\"path\":\"/age\"}"} = Jsonpatch.Coder.encode(add_patch)

    remove_patch = %Jsonpatch.Operation.Remove{path: "/age"}
    assert {:ok, "{\"op\":\"remove\",\"path\":\"/age\"}"} = Jsonpatch.Coder.encode(remove_patch)

    replace_patch = %Jsonpatch.Operation.Replace{path: "/name", value: "Bob"}
    assert {:ok, "{\"op\":\"replace\",\"value\":\"Bob\",\"path\":\"/name\"}"} = Jsonpatch.Coder.encode(replace_patch)
  end
end
