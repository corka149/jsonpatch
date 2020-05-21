defmodule Jsonpatch.CoderTest do
  use ExUnit.Case

  test "encode list of JSON patches" do
    patch = [
      %Jsonpatch.Operation.Add{path: "/age", value: 1},
      %Jsonpatch.Operation.Remove{path: "/age"},
      %Jsonpatch.Operation.Replace{path: "/name", value: "Bob"}
    ]

    json_patch = Jsonpatch.Coder.encode(patch)

    expected_json_patch_str =
      "[{\"value\":1,\"path\":\"/age\",\"op\":\"add\"},{\"path\":\"/age\",\"op\":\"remove\"},{\"value\":\"Bob\",\"path\":\"/name\",\"op\":\"replace\"}]"

    assert {:ok, ^expected_json_patch_str} = json_patch
  end

  test "encode single operations" do
    add_patch = %Jsonpatch.Operation.Add{path: "/age", value: 1}

    assert {:ok, "{\"value\":1,\"path\":\"/age\",\"op\":\"add\"}"} =
             Jsonpatch.Coder.encode(add_patch)

    remove_patch = %Jsonpatch.Operation.Remove{path: "/age"}
    assert {:ok, "{\"path\":\"/age\",\"op\":\"remove\"}"} = Jsonpatch.Coder.encode(remove_patch)

    replace_patch = %Jsonpatch.Operation.Replace{path: "/name", value: "Bob"}

    assert {:ok, "{\"value\":\"Bob\",\"path\":\"/name\",\"op\":\"replace\"}"} =
             Jsonpatch.Coder.encode(replace_patch)

    copy_patch = %Jsonpatch.Operation.Copy{from: "/name", path: "/surname"}

    assert {:ok, "{\"path\":\"/surname\",\"op\":\"copy\",\"from\":\"/name\"}"} =
             Jsonpatch.Coder.encode(copy_patch)

    move_patch = %Jsonpatch.Operation.Move{from: "/home", path: "/work"}

    assert {:ok, "{\"path\":\"/work\",\"op\":\"move\",\"from\":\"/home\"}"} =
             Jsonpatch.Coder.encode(move_patch)

    test_patch = %Jsonpatch.Operation.Test{path: "age", value: "1"}
    assert {:ok, "{\"value\":\"1\",\"path\":\"age\",\"op\":\"test\"}"} = Jsonpatch.Coder.encode(test_patch)
  end

  test "decode a list of JSON patches" do
    patch_str =
      "[{\"value\":1,\"path\":\"/age\",\"op\":\"add\"},{\"path\":\"/age\",\"op\":\"remove\"},{\"value\":\"Bob\",\"path\":\"/name\",\"op\":\"replace\"},{\"path\":\"/surname\",\"op\":\"copy\",\"from\":\"/name\"},{\"path\":\"/work\",\"op\":\"move\",\"from\":\"/home\"},{\"value\":\"1\",\"path\":\"age\",\"op\":\"test\"}]"

    json_patch = Jsonpatch.Coder.decode(patch_str)

    expected_patch = [
      %Jsonpatch.Operation.Add{path: "/age", value: 1},
      %Jsonpatch.Operation.Remove{path: "/age"},
      %Jsonpatch.Operation.Replace{path: "/name", value: "Bob"},
      %Jsonpatch.Operation.Copy{from: "/name", path: "/surname"},
      %Jsonpatch.Operation.Move{from: "/home", path: "/work"},
      %Jsonpatch.Operation.Test{path: "age", value: "1"}
    ]

    assert ^expected_patch = json_patch
  end

  test "decode single operations" do
    add_patch_str = "{\"value\":1,\"path\":\"/age\",\"op\":\"add\"}"
    assert %Jsonpatch.Operation.Add{path: "/age", value: 1} =
             Jsonpatch.Coder.decode(add_patch_str)

    remove_patch_str = "{\"path\":\"/age\",\"op\":\"remove\"}"
    assert %Jsonpatch.Operation.Remove{path: "/age"} = Jsonpatch.Coder.decode(remove_patch_str)

    replace_patch_str = "{\"value\":\"Bob\",\"path\":\"/name\",\"op\":\"replace\"}"
    assert %Jsonpatch.Operation.Replace{path: "/name", value: "Bob"} =
             Jsonpatch.Coder.decode(replace_patch_str)

    copy_patch_str = "{\"path\":\"/name\",\"from\":\"/surname\",\"op\":\"copy\"}"
    assert %Jsonpatch.Operation.Copy{path: "/name", from: "/surname"} =
            Jsonpatch.Coder.decode(copy_patch_str)

    move_patch_str = "{\"path\":\"/name\",\"from\":\"/surname\",\"op\":\"move\"}"
    assert %Jsonpatch.Operation.Move{path: "/name", from: "/surname"} =
            Jsonpatch.Coder.decode(move_patch_str)

    test_patch_str = "{\"value\":1,\"path\":\"/age\",\"op\":\"test\"}"
    assert %Jsonpatch.Operation.Test{path: "/age", value: 1} =
            Jsonpatch.Coder.decode(test_patch_str)
  end
end
