defmodule JsonpatchTest do
  use ExUnit.Case

  doctest Jsonpatch

  defmodule TestStruct do
    defstruct [:field1, :field2, :inner, :field]
  end

  test "Create diff from list and apply it" do
    # Arrange
    source = [1, 2, %{"drei" => 3}, 5, 6]
    destination = [1, 2, %{"three" => 3}, 4, 5]

    # Act
    patch = Jsonpatch.diff(source, destination)

    patched_source = Jsonpatch.apply_patch!(patch, source)

    # Assert
    assert ^destination = patched_source
  end

  describe "Create diffs" do
    test "adding an Object Member" do
      source = %{"foo" => "bar"}
      destination = %{"foo" => "bar", "baz" => "qux"}

      assert_diff_apply(source, destination)
    end

    test "Adding an Array Element" do
      source = %{"foo" => ["bar", "baz"]}
      destination = %{"foo" => ["bar", "baz", "qux"]}

      assert_diff_apply(source, destination)
    end

    test "Removing an Object Member" do
      source = %{"baz" => "qux", "foo" => "bar"}
      destination = %{"foo" => "bar"}

      assert_diff_apply(source, destination)
    end

    test "Create no diff on unchanged nil object value" do
      source = %{"id" => nil}
      destination = %{"id" => nil}

      assert [] = Jsonpatch.diff(source, destination)
    end

    test "Create no diff on unchanged array value" do
      source = [nil]
      destination = [nil]

      assert [] = Jsonpatch.diff(source, destination)
    end

    test "Create full replace operation when type of root value changes" do
      assert [%{op: "replace", path: "", value: 1}] = Jsonpatch.diff("unexpected", 1)
    end

    test "A.4. Removing an Array Element" do
      source = %{"a" => %{"b" => ["c", "d"]}}
      destination = %{"a" => %{"b" => ["c"]}}

      assert_diff_apply(source, destination)
    end

    test "Replacing a Value" do
      source = %{"a" => %{"b" => %{"c" => "d"}}, "f" => "g"}
      destination = %{"a" => %{"b" => %{"c" => "h"}}, "f" => "g"}

      assert_diff_apply(source, destination)
    end

    test "Replacing an Array Element" do
      source = %{"a" => %{"b" => %{"c" => ["d1", "d2"]}}, "f" => "g"}
      destination = %{"a" => %{"b" => %{"c" => ["d1", "d3"]}}, "f" => "g"}

      assert_diff_apply(source, destination)
    end

    test "Create diff with escaped '~' and '/' in path when adding" do
      source = %{}
      destination = %{"escape/me~now" => "somnevalue"}

      assert_diff_apply(source, destination)
    end

    test "Create diff with escaped '~' and '/' in path when removing" do
      source = %{"escape/me~now" => "somnevalue"}
      destination = %{}

      assert_diff_apply(source, destination)
    end

    test "Create diff with escaped '~' and '/' in path when replacing" do
      source = %{"escape/me~now" => "somnevalue"}
      destination = %{"escape/me~now" => "othervalue"}

      assert_diff_apply(source, destination)
    end

    test "Create diff with nested map with correct Add/Remove order" do
      source = %{"a" => [%{"b" => []}]}
      destination = %{"a" => [%{"b" => [%{"c" => 1}, %{"d" => 2}]}]}

      assert_diff_apply(source, destination)

      source = %{"a" => [%{"b" => [%{"c" => 1}, %{"d" => 2}]}]}
      destination = %{"a" => [%{"b" => []}]}

      assert_diff_apply(source, destination)
    end

    test "Create diff that replace list with map" do
      source = %{"a" => [1, 2, 3]}
      destination = %{"a" => %{"foo" => :bar}}

      assert_diff_apply(source, destination)
    end

    test "Create diff when source has a scalar value where in the destination is a list" do
      source = %{"a" => 150}
      destination = %{"a" => [1, 5, 0]}

      assert_diff_apply(source, destination)
    end

    test "Create diff for lists" do
      source = [1, "pizza", %{"name" => "Alice"}, [4, 2]]
      destination = [1, "hamburger", %{"name" => "Alice", "age" => 55}]

      assert_diff_apply(source, destination)
    end

    test "Create diff for map with atoms as key" do
      source = %{atom: [1, 2]}
      destination = %{atom: [1, 2, 3]}

      patches = Jsonpatch.diff(source, destination)
      assert Jsonpatch.apply_patch(patches, source, keys: :atoms) == {:ok, destination}
    end

    test "Create diff with ancestor_path option for nested maps" do
      source = %{"a" => 1}
      destination = %{"a" => 3}

      patches = Jsonpatch.diff(source, destination, ancestor_path: "/nested/object")

      assert patches == [
               %{op: "replace", path: "/nested/object/a", value: 3}
             ]
    end

    test "Create diff with ancestor_path option for nested lists" do
      source = [1, 2, 3]
      destination = [1, 2, 4]

      patches = Jsonpatch.diff(source, destination, ancestor_path: "/items")

      assert patches == [
               %{op: "replace", path: "/items/2", value: 4}
             ]
    end

    test "Create diff with empty ancestor_path (default behavior)" do
      source = %{"a" => 1, "b" => 2}
      destination = %{"a" => 3, "c" => 4}

      patches_with_option = Jsonpatch.diff(source, destination, ancestor_path: "")
      patches_without_option = Jsonpatch.diff(source, destination)

      assert patches_with_option == patches_without_option
    end

    test "Create diff with ancestor_path containing escaped characters" do
      source = %{"a" => 1}
      destination = %{"a" => 2}

      patches = Jsonpatch.diff(source, destination, ancestor_path: "/escape~1me~0now")

      assert patches == [
               %{op: "replace", path: "/escape~1me~0now/a", value: 2}
             ]
    end

    test "Create diff with prepare_map option using subset of fields" do
      source = %TestStruct{
        field1: "value1",
        field2: "value2",
        inner: %{nested: "old"},
        field: "ignored"
      }

      destination = %TestStruct{
        field1: "new_value",
        field2: "value2",
        inner: %{nested: "new"},
        field: "also_ignored"
      }

      patches =
        Jsonpatch.diff(source, destination,
          prepare_map: fn
            %TestStruct{field1: field1, inner: inner} -> %{field1: field1, inner: inner}
            map -> map
          end
        )

      expected_patches = [
        %{op: "replace", path: "/field1", value: "new_value"},
        %{op: "replace", path: "/inner/nested", value: "new"}
      ]

      assert_equal_patches(patches, expected_patches)
    end

    test "Create diff with prepare_map option using dynamic field creation" do
      source = %TestStruct{
        field1: "hello",
        field2: "world"
      }

      destination = %TestStruct{
        field1: "hi",
        field2: "world"
      }

      patches =
        Jsonpatch.diff(source, destination,
          prepare_map: &%{field3: "#{&1.field1} - #{&1.field2}"}
        )

      expected_patches = [
        %{op: "replace", path: "/field3", value: "hi - world"}
      ]

      assert_equal_patches(patches, expected_patches)
    end

    test "Create diff with prepare_map option using nested dynamic field creation" do
      source = %TestStruct{
        field1: "hello",
        field2: "world",
        inner: %TestStruct{field1: "nested", field2: "old"}
      }

      destination = %TestStruct{
        field1: "hi",
        field2: "world",
        inner: %TestStruct{field1: "nested", field2: "new"}
      }

      patches =
        Jsonpatch.diff(source, destination,
          prepare_map: &%{inner: &1.inner, field3: "#{&1.field1} - #{&1.field2}"}
        )

      expected_patches = [
        %{op: "replace", path: "/field3", value: "hi - world"},
        %{op: "replace", path: "/inner/field3", value: "nested - new"}
      ]

      assert_equal_patches(patches, expected_patches)
    end

    test "add map patches are correctly processed by prepare_map" do
      source = %{}

      destination = %{
        a: %TestStruct{
          field1: "hi",
          field2: "world"
        }
      }

      patches =
        Jsonpatch.diff(source, destination,
          prepare_map: fn
            %TestStruct{field1: field1} -> %{field1: field1}
            map -> map
          end
        )

      assert patches == [
               %{op: "add", path: "/a", value: %{field1: "hi"}}
             ]
    end

    test "add list patches are correctly processed by prepare_map" do
      source = []

      destination = [
        %TestStruct{
          field1: "hi",
          field2: "world"
        }
      ]

      patches = Jsonpatch.diff(source, destination, prepare_map: &%{field1: &1.field1})

      assert patches == [
               %{op: "add", path: "/0", value: %{field1: "hi"}}
             ]
    end

    test "replace map patches are correctly processed by prepare_map" do
      source = %{"a" => "test"}
      destination = %{"a" => %TestStruct{field1: "old"}}

      patches =
        Jsonpatch.diff(source, destination,
          prepare_map: fn
            %TestStruct{field1: field1} -> %{field1: field1}
            map -> map
          end
        )

      assert patches == [
               %{op: "replace", path: "/a", value: %{field1: "old"}}
             ]
    end

    test "replace_map changing type of value is also supported" do
      source = %{"a" => ~D[2025-01-01]}
      destination = %{"a" => ~D[2025-01-02]}

      patches =
        Jsonpatch.diff(source, destination,
          prepare_map: fn
            %Date{year: year, month: month, day: day} -> "#{year}-#{month}-#{day}"
            map -> map
          end
        )

      assert patches == [
               %{op: "replace", path: "/a", value: "2025-1-2"}
             ]
    end

    test "Create diff with ancestor_path when changing type of base value (map to nil)" do
      source = %{"key" => "value"}
      destination = nil

      patches = Jsonpatch.diff(source, destination, ancestor_path: "/nested")

      # This should fail for now - the diff should not handle type changes with ancestor_path
      # The expected behavior would be to generate a replace operation for the entire data object
      expected_patches = [
        %{op: "replace", path: "/nested", value: nil}
      ]

      assert patches == expected_patches
    end

    defp assert_diff_apply(source, destination) do
      patches = Jsonpatch.diff(source, destination)
      assert Jsonpatch.apply_patch(patches, source) == {:ok, destination}
    end

    test "Create diff with object_hash for list items - simple insertion" do
      original = [
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"},
        %{id: 3, name: "test3"}
      ]

      updated = List.insert_at(original, 0, %{id: 123, name: "test123"})

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)

      # Should only have one add operation instead of multiple replace operations
      assert patches == [
               %{value: %{id: 123, name: "test123"}, path: "/0", op: "add"}
             ]
    end

    test "Create diff with object_hash for list items - simple insertion with prepare_map" do
      original = []

      updated = [
        %{id: 1, name: "test1"}
      ]

      patches =
        Jsonpatch.diff(original, updated,
          object_hash: fn %{id: id} -> id end,
          prepare_map: fn %{id: id} -> %{id: id} end
        )

      expected_patches = [
        %{value: %{id: 1}, path: "/0", op: "add"}
      ]

      # Apply the patch and verify it works
      assert_equal_patches(patches, expected_patches)
    end

    test "Create diff with object_hash for list items - reordering" do
      original = [
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"},
        %{id: 3, name: "test3"}
      ]

      updated = [
        %{id: 3, name: "test3"},
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      # Apply the patch and verify it works
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash for list items - removal" do
      original = [
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"},
        %{id: 3, name: "test3"}
      ]

      updated = [
        %{id: 1, name: "test1"},
        %{id: 3, name: "test3"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)

      # Should only have one remove operation
      assert patches == [
               %{path: "/1", op: "remove"}
             ]
    end

    test "Create diff with object_hash for list items - modification" do
      original = [
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"}
      ]

      updated = [
        %{id: 1, name: "modified1"},
        %{id: 2, name: "test2"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)

      # Should only modify the changed field
      assert patches == [
               %{value: "modified1", path: "/0/name", op: "replace"}
             ]
    end

    test "Create diff with object_hash validates opts" do
      original = [%{id: 1, name: "test1"}]
      updated = [%{id: 1, name: "test1"}]

      # Should raise when invalid opts are provided
      assert_raise ArgumentError, fn ->
        Jsonpatch.diff(original, updated, invalid_option: "value")
      end
    end

    test "Create diff with object_hash falls back to index-based when function not provided" do
      original = [%{id: 1, name: "test1"}]
      updated = [%{id: 2, name: "test2"}]

      # Should work the same as before when no object_hash is provided
      patches_with_opts = Jsonpatch.diff(original, updated, [])
      patches_without_opts = Jsonpatch.diff(original, updated)

      assert patches_with_opts == patches_without_opts
    end

    test "Create diff with object_hash - inserting at the beginning" do
      original = [
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"}
      ]

      updated = [
        %{id: 3, name: "test3"},
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert patches == [%{op: "add", path: "/0", value: %{id: 3, name: "test3"}}]
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - inserting in the middle" do
      original = [
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"}
      ]

      updated = [
        %{id: 1, name: "test1"},
        %{id: 3, name: "test3"},
        %{id: 2, name: "test2"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert patches == [%{op: "add", path: "/1", value: %{id: 3, name: "test3"}}]
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - removing in the middle" do
      original = [
        %{id: 1, name: "test1"},
        %{id: 2, name: "test2"},
        %{id: 3, name: "test3"}
      ]

      updated = [
        %{id: 1, name: "test1"},
        %{id: 3, name: "test3"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert patches == [%{op: "remove", path: "/1"}]
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - complex reordering with modifications" do
      original = [
        %{id: 1, name: "first", status: "active"},
        %{id: 2, name: "second", status: "inactive"},
        %{id: 3, name: "third", status: "active"},
        %{id: 4, name: "fourth", status: "pending"}
      ]

      updated = [
        # moved from end, status changed
        %{id: 4, name: "fourth", status: "active"},
        # moved and name changed
        %{id: 2, name: "second-modified", status: "inactive"},
        # moved and status changed
        %{id: 1, name: "first", status: "inactive"},
        # moved, no changes
        %{id: 3, name: "third", status: "active"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - simultaneous add, remove, move, and modify" do
      original = [
        %{id: 1, name: "keep1", value: 10},
        %{id: 2, name: "remove_me", value: 20},
        %{id: 3, name: "move_me", value: 30},
        %{id: 4, name: "modify_me", value: 40}
      ]

      updated = [
        # new item at start
        %{id: 5, name: "new_item", value: 50},
        # modified and moved
        %{id: 4, name: "modified", value: 45},
        # unchanged
        %{id: 1, name: "keep1", value: 10},
        # moved but unchanged
        %{id: 3, name: "move_me", value: 30},
        # new item at end
        %{id: 6, name: "another_new", value: 60}
      ]

      # id: 2 is removed

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - multiple insertions at different positions" do
      original = [
        %{id: 1, name: "first"},
        %{id: 3, name: "third"},
        %{id: 5, name: "fifth"}
      ]

      updated = [
        # insert at beginning
        %{id: 0, name: "zero"},
        %{id: 1, name: "first"},
        # insert in middle
        %{id: 2, name: "second"},
        %{id: 3, name: "third"},
        # insert in middle
        %{id: 4, name: "fourth"},
        %{id: 5, name: "fifth"},
        # insert at end
        %{id: 6, name: "sixth"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, ^updated} = Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - multiple removals at different positions" do
      original = [
        %{id: 1, name: "first"},
        %{id: 2, name: "second"},
        %{id: 3, name: "third"},
        %{id: 4, name: "fourth"},
        %{id: 5, name: "fifth"},
        %{id: 6, name: "sixth"}
      ]

      updated = [
        # removed first
        %{id: 2, name: "second"},
        # removed third and fifth
        %{id: 4, name: "fourth"},
        # removed sixth would be here but it's kept
        %{id: 6, name: "sixth"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - reverse order" do
      original = [
        %{id: 1},
        %{id: 2},
        %{id: 3}
      ]

      updated = [
        %{id: 3},
        %{id: 2},
        %{id: 1}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, ^updated} = Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - reverse order with modifications" do
      original = [
        %{id: 1, name: "first", count: 1},
        %{id: 2, name: "second", count: 2},
        %{id: 3, name: "third", count: 3}
      ]

      updated = [
        # reversed and modified
        %{id: 3, name: "third-modified", count: 30},
        # reversed and count modified
        %{id: 2, name: "second", count: 20},
        # reversed and name modified
        %{id: 1, name: "first-new", count: 1}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, ^updated} = Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - empty to populated list" do
      original = []

      updated = [
        %{id: 1, name: "first"},
        %{id: 2, name: "second"},
        %{id: 3, name: "third"}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, ^updated} = Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - populated to empty list" do
      original = [
        %{id: 1, name: "first"},
        %{id: 2, name: "second"},
        %{id: 3, name: "third"}
      ]

      updated = []

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, ^updated} = Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - duplicate hash values handled gracefully" do
      original = [
        %{id: 1, name: "first", group: "A"},
        %{id: 2, name: "second", group: "A"},
        %{id: 3, name: "third", group: "B"}
      ]

      updated = [
        %{id: 1, name: "first-modified", group: "A"},
        %{id: 3, name: "third", group: "B"},
        %{id: 2, name: "second", group: "A"}
      ]

      # Using group as hash (which has duplicates) should still work
      patches = Jsonpatch.diff(original, updated, object_hash: fn %{group: group} -> group end)
      assert {:ok, ^updated} = Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - nested objects with modifications" do
      original = [
        %{id: 1, user: %{name: "Alice", age: 30}, tags: ["admin"]},
        %{id: 2, user: %{name: "Bob", age: 25}, tags: ["user"]},
        %{id: 3, user: %{name: "Charlie", age: 35}, tags: ["user", "premium"]}
      ]

      updated = [
        # moved, age and tags changed
        %{id: 2, user: %{name: "Bob", age: 26}, tags: ["user", "active"]},
        # moved, tags changed
        %{id: 1, user: %{name: "Alice", age: 30}, tags: ["admin", "senior"]},
        # new item
        %{id: 4, user: %{name: "David", age: 28}, tags: ["user"]},
        # moved, tags changed
        %{id: 3, user: %{name: "Charlie", age: 35}, tags: ["premium"]}
      ]

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - mixed data types in list" do
      original = [
        %{id: 1, name: "object1"},
        %{id: 2, name: "object2"},
        %{id: 3, name: "object3"}
      ]

      updated = [
        %{id: 2, name: "object2-modified"},
        %{id: 1, name: "object1"},
        # new item
        %{id: 4, name: "object4"}
      ]

      # id: 3 removed

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - large list reordering" do
      # Create a larger list to test performance characteristics
      original = Enum.map(1..10, fn i -> %{id: i, name: "item#{i}", value: i * 10} end)

      # Reverse the order and modify every 5th item
      updated = original |> tl |> Enum.reverse()

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end

    test "Create diff with object_hash - interleaved additions and removals" do
      original = [
        %{id: 1, name: "keep1"},
        %{id: 2, name: "remove1"},
        %{id: 3, name: "keep2"},
        %{id: 4, name: "remove2"},
        %{id: 5, name: "keep3"}
      ]

      updated = [
        %{id: 1, name: "keep1"},
        # new
        %{id: 10, name: "add1"},
        %{id: 3, name: "keep2"},
        # new
        %{id: 11, name: "add2"},
        %{id: 5, name: "keep3"},
        # new
        %{id: 12, name: "add3"}
      ]

      # removed id: 2 and 4

      patches = Jsonpatch.diff(original, updated, object_hash: fn %{id: id} -> id end)
      assert {:ok, updated} == Jsonpatch.apply_patch(patches, original, keys: :atoms)
    end
  end

  describe "Apply patch/es" do
    test "invalid json patch specification" do
      patch = %{"invalid" => "invalid"}

      assert {:error,
              %Jsonpatch.Error{
                patch: ^patch,
                patch_index: 0,
                reason: {:invalid_spec, %{"invalid" => "invalid"}}
              }} = Jsonpatch.apply_patch(patch, %{})
    end

    test "Apply patch with invalid source path and expect error" do
      target = %{
        "name" => "Bob",
        "married" => false,
        "hobbies" => ["Sport", "Elixir", "Football"],
        "home" => "Berlin"
      }

      patch = %{"op" => "add", "path" => "/child/0/age", "value" => 33}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["child"]}}} =
               Jsonpatch.apply_patch(patch, target)

      patch = %{"op" => "replace", "path" => "/age", "value" => 42}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["age"]}}} =
               Jsonpatch.apply_patch(patch, target)

      patch = %{"op" => "remove", "path" => "/hobby/4"}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["hobby"]}}} =
               Jsonpatch.apply_patch(patch, target)

      patch = %{"from" => "/nameX", "op" => "copy", "path" => "/surname"}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["nameX"]}}} =
               Jsonpatch.apply_patch(patch, target)

      patch = %{"from" => "/homeX", "op" => "move", "path" => "/work"}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["homeX"]}}} =
               Jsonpatch.apply_patch(patch, target)
    end

    test "Apply patch with multiple operations with binary keys" do
      patch = [
        %Jsonpatch.Operation.Remove{path: "/age"},
        %Jsonpatch.Operation.Add{path: "/age", value: 34},
        %Jsonpatch.Operation.Replace{path: "/age", value: 35}
      ]

      target = %{"age" => "33"}
      patched = Jsonpatch.apply_patch!(patch, target)

      assert %{"age" => 35} = patched
    end

    test "Apply patch with multiple operations with atom keys" do
      patch = [
        %Jsonpatch.Operation.Remove{path: "/age"},
        %Jsonpatch.Operation.Add{path: "/age", value: 34},
        %Jsonpatch.Operation.Replace{path: "/age", value: 35}
      ]

      target = %{age: "33"}
      patched = Jsonpatch.apply_patch!(patch, target, keys: :atoms!)

      assert %{age: 35} = patched
    end

    test "Apply patch with non existing atom" do
      target = %{}

      patch = %{"op" => "add", "path" => "/test_non_existing_atom", "value" => 34}

      assert {:error,
              %Jsonpatch.Error{
                patch: ^patch,
                patch_index: 0,
                reason: {:invalid_path, ["test_non_existing_atom"]}
              }} = Jsonpatch.apply_patch(patch, target, keys: :atoms!)
    end

    test "Apply patch with custom keys option - example 1" do
      patch = [
        %Jsonpatch.Operation.Replace{path: "/a1/b/c", value: 1},
        %Jsonpatch.Operation.Replace{path: "/a2/b/d", value: 1}
      ]

      target = %{a1: %{b: %{"c" => 0}}, l: [], a2: %{b: %{"d" => 0}}}

      convert_fn = fn
        # All map keys are atoms except /*/b/* keys
        fragment, [_, :b], target, _opts when is_map(target) ->
          {:ok, fragment}

        fragment, _path, target, _opts when is_map(target) ->
          string_to_existing_atom(fragment)

        fragment, path, target, _opts when is_list(target) ->
          case Jsonpatch.Utils.cast_index(fragment, path, target) do
            {:ok, _} = ok -> ok
            {:error, _} -> :error
          end
      end

      patched = Jsonpatch.apply_patch!(patch, target, keys: {:custom, convert_fn})
      assert %{a1: %{b: %{"c" => 1}}, a2: %{b: %{"d" => 1}}} = patched

      patch = %Jsonpatch.Operation.Add{path: "/l/0", value: 1}
      patched = Jsonpatch.apply_patch!(patch, target, keys: {:custom, convert_fn})
      assert %{a1: %{b: %{"c" => 0}}, l: [1], a2: %{b: %{"d" => 0}}} = patched

      patch = %{"op" => "replace", "path" => "/not_existing_atom", "value" => 1}

      assert {:error,
              %Jsonpatch.Error{
                patch: ^patch,
                patch_index: 0,
                reason: {:invalid_path, ["not_existing_atom"]}
              }} = Jsonpatch.apply_patch(patch, target, keys: {:custom, convert_fn})

      patch = %{"op" => "replace", "path" => "/l/not_existing_atom", "value" => 20}

      assert {:error,
              %Jsonpatch.Error{
                patch: ^patch,
                patch_index: 0,
                reason: {:invalid_path, [:l, "not_existing_atom"]}
              }} = Jsonpatch.apply_patch(patch, target, keys: {:custom, convert_fn})
    end

    test "struct are just maps" do
      patch = %Jsonpatch.Operation.Replace{path: "/a/field1/c", value: 1}
      target = %{a: %TestStruct{field1: %{c: 0}}}
      patched = Jsonpatch.apply_patch!(patch, target, keys: :atoms)
      assert %{a: %TestStruct{field1: %{c: 1}}} = patched

      patch = %Jsonpatch.Operation.Remove{path: "/a/field1"}
      target = %{a: %TestStruct{field1: %{c: 0}}}
      patched = Jsonpatch.apply_patch!(patch, target, keys: :atoms)
      assert %{a: %{__struct__: TestStruct}} = patched
    end

    test "Apply patch with invalid target source path and expect error" do
      target = %{
        "name" => "Bob",
        "married" => false,
        "hobbies" => ["Sport", "Elixir", "Football"],
        "home" => "Berlin"
      }

      patch = %{"op" => "copy", "from" => "/name", "path" => "/xyz/surname"}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["xyz"]}}} =
               Jsonpatch.apply_patch(patch, target)

      patch = %{"from" => "/home", "op" => "move", "path" => "/xyz/work"}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["xyz"]}}} =
               Jsonpatch.apply_patch(patch, target)

      patch = %{"op" => "remove", "path" => "/xyz/work"}

      assert {:error,
              %Jsonpatch.Error{patch: ^patch, patch_index: 0, reason: {:invalid_path, ["xyz"]}}} =
               Jsonpatch.apply_patch(patch, target)
    end

    test "Apply patch with one invalid path and expect error" do
      patch = [
        %Jsonpatch.Operation.Add{path: "/age", value: 33},
        %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
        %Jsonpatch.Operation.Replace{path: "/married", value: true},
        %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
        # Should fail
        %Jsonpatch.Operation.Remove{path: "/hobbies/4"},
        %Jsonpatch.Operation.Copy{from: "/name", path: "/surname"},
        %Jsonpatch.Operation.Move{from: "/home", path: "/work"},
        %Jsonpatch.Operation.Test{path: "/name", value: "Bob"}
      ]

      target = %{
        "name" => "Bob",
        "married" => false,
        "hobbies" => ["Sport", "Elixir", "Football"],
        "home" => "Berlin"
      }

      assert {:error,
              %Jsonpatch.Error{
                patch: %{"op" => "remove", "path" => "/hobbies/4"},
                patch_index: 4,
                reason: {:invalid_path, ["hobbies", "4"]}
              }} = Jsonpatch.apply_patch(patch, target)
    end

    test "Apply patch with failing test and expect error" do
      patch = [
        %Jsonpatch.Operation.Add{path: "/age", value: 33},
        %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
        %Jsonpatch.Operation.Replace{path: "/married", value: true},
        %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
        %Jsonpatch.Operation.Copy{from: "/name", path: "/surname"},
        %Jsonpatch.Operation.Move{from: "/home", path: "/work"},
        # Name is Bob therefore this should fail
        %Jsonpatch.Operation.Test{path: "/name", value: "Alice"},
        # Should never be applied
        %Jsonpatch.Operation.Test{path: "/year", value: 1980}
      ]

      target = %{
        "name" => "Bob",
        "married" => false,
        "hobbies" => ["Sport", "Elixir", "Football"],
        "home" => "Berlin"
      }

      assert {:error,
              %Jsonpatch.Error{
                patch: %{"op" => "test", "path" => "/name", "value" => "Alice"},
                patch_index: 6,
                reason: {:test_failed, "Expected value '\"Alice\"' at '/name'"}
              }} = Jsonpatch.apply_patch(patch, target)
    end

    test "Apply patch with escaped '~' and '/' in path" do
      patch = [
        %Jsonpatch.Operation.Add{path: "/foo/escape~1me~0now", value: "somnevalue"},
        %Jsonpatch.Operation.Remove{path: "/bar/escape~1me~0now"}
      ]

      target = %{"foo" => %{}, "bar" => %{"escape/me~now" => 5}}

      assert {:ok, %{"foo" => %{"escape/me~now" => "somnevalue"}, "bar" => %{}}} =
               Jsonpatch.apply_patch(patch, target)
    end

    test "Apply patch with '!' and expect valid result" do
      patch = %Jsonpatch.Operation.Remove{path: "/name"}
      target = %{"name" => "Alice", "age" => 44}

      patched = Jsonpatch.apply_patch!(patch, target)
      assert %{"age" => 44} = patched
    end

    test "Apply patch with '!' and expect exception" do
      patch = %Jsonpatch.Operation.Replace{path: "/surname", value: "Misty"}
      target = %{"name" => "Alice", "age" => 44}

      assert_raise JsonpatchException, fn -> Jsonpatch.apply_patch!(patch, target) end
    end

    test "Apply patch with a path containing an empty key" do
      patch = %Jsonpatch.Operation.Replace{path: "/a/", value: 35}
      target = %{"a" => %{"" => 33}}

      assert {:ok, %{"a" => %{"" => 35}}} = Jsonpatch.apply_patch(patch, target)
    end

    for %{
          "comment" => comment,
          "doc" => target,
          "expected" => expected,
          "patch" => patch
        } = test_case <-
          File.read!("./test/json-patch-tests.json") |> Jason.decode!(),
        !test_case["disabled"] do
      @data %{target: target, expected: expected, patch: patch}

      test comment do
        expected = @data.expected
        patch = @data.patch
        target = @data.target

        assert {:ok, ^expected} = Jsonpatch.apply_patch(patch, target)
      end
    end

    test "ignore invalid paths when asked to" do
      patch = %{"op" => "replace", "path" => "/inexistent", "value" => 42}
      target = %{"foo" => "bar"}

      assert {:ok, %{"foo" => "bar"}} =
               Jsonpatch.apply_patch(patch, target, ignore_invalid_paths: true)
    end
  end

  defp assert_equal_patches(patches1, patches2) do
    assert Enum.sort_by(patches1, & &1.path) == Enum.sort_by(patches2, & &1.path)
  end

  defp string_to_existing_atom(data) when is_binary(data) do
    {:ok, String.to_existing_atom(data)}
  rescue
    ArgumentError -> :error
  end
end
