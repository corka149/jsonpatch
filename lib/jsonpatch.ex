defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.

  The patch can be a single change or a list of things that shall be changed. Therefore
  a list or a single JSON patch can be provided. Every patch belongs to a certain operation
  which influences the usage.

  According to [RFC 6901](https://tools.ietf.org/html/rfc6901) escaping of `/` and `~` is done
  by using `~1` for `/` and `~0` for `~`.
  """

  alias Jsonpatch.Types
  alias Jsonpatch.Operation.{Add, Copy, Move, Remove, Replace, Test}

  @typedoc """
  A valid Jsonpatch operation by RFC 6902
  """
  @type t :: map() | Add.t() | Remove.t() | Replace.t() | Copy.t() | Move.t() | Test.t()

  @doc """
  Apply a Jsonpatch or a list of Jsonpatches to a map or struct. The whole patch will not be applied
  when any path is invalid or any other error occured. When a list is provided, the operations are
  applied in the order as they appear in the list.

  Atoms are never garbage collected. Therefore, `Jsonpatch` works by default only with maps
  which used binary strings as key. This behaviour can be controlled via the `:keys` option.

  ## Examples
      iex> patch = [
      ...> %{op: "add", path: "/age", value: 33},
      ...> %{op: "replace", path: "/hobbies/0", value: "Elixir!"},
      ...> %{op: "replace", path: "/married", value: true},
      ...> %{op: "remove", path: "/hobbies/2"},
      ...> %{op: "remove", path: "/hobbies/1"},
      ...> %{op: "copy", from: "/name", path: "/surname"},
      ...> %{op: "move", from: "/home", path: "/work"},
      ...> %{op: "test", path: "/name", value: "Bob"}
      ...> ]
      iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
      iex> Jsonpatch.apply_patch(patch, target)
      {:ok, %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33, "surname" => "Bob", "work" => "Berlin"}}

      iex> # Patch will not be applied if test fails. The target will not be changed.
      iex> patch = [
      ...> %{op: "add", path: "/age", value: 33},
      ...> %{op: "test", path: "/name", value: "Alice"}
      ...> ]
      iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
      iex> Jsonpatch.apply_patch(patch, target)
      {:error, %Jsonpatch.Error{patch: %{"op" => "test", "path" => "/name", "value" => "Alice"}, patch_index: 1, reason: {:test_failed, "Expected value '\\"Alice\\"' at '/name'"}}}

      iex> # Patch will succeed, not applying invalid path operations.
      iex> patch = [
      ...> %{op: "replace", path: "/name", value: "Alice"},
      ...> %{op: "replace", path: "/age", value: 42}
      ...> ]
      iex> target = %{"name" => "Bob"} # No age in target
      iex> Jsonpatch.apply_patch(patch, target, ignore_invalid_paths: true)
      {:ok, %{"name" => "Alice"}}
  """
  @spec apply_patch(t() | [t()], target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | {:error, Jsonpatch.Error.t()}
  def apply_patch(json_patch, target, opts \\ []) do
    # https://datatracker.ietf.org/doc/html/rfc6902#section-3
    # > Operations are applied sequentially in the order they appear in the array.
    {ignore_invalid_paths?, opts} = Keyword.pop(opts, :ignore_invalid_paths, false)

    json_patch
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, target}, fn {patch, patch_index}, {:ok, acc} ->
      patch = cast_to_op_map(patch)

      do_apply_patch(patch, acc, opts)
      |> handle_patch_result(acc, patch, patch_index, ignore_invalid_paths?)
    end)
  end

  defp handle_patch_result(result, acc, patch, patch_index, ignore_invalid_paths?) do
    case result do
      {:error, {error, _} = reason} ->
        if ignore_invalid_paths? && error == :invalid_path do
          {:cont, {:ok, acc}}
        else
          error = %Jsonpatch.Error{patch: patch, patch_index: patch_index, reason: reason}
          {:halt, {:error, error}}
        end

      {:ok, res} ->
        {:cont, {:ok, res}}
    end
  end

  defp cast_to_op_map(%struct_mod{} = json_patch) do
    json_patch =
      json_patch
      |> Map.from_struct()

    op =
      case struct_mod do
        Add -> "add"
        Remove -> "remove"
        Replace -> "replace"
        Copy -> "copy"
        Move -> "move"
        Test -> "test"
      end

    json_patch = Map.put(json_patch, "op", op)

    cast_to_op_map(json_patch)
  end

  defp cast_to_op_map(json_patch) do
    Map.new(json_patch, fn {k, v} -> {to_string(k), v} end)
  end

  defp do_apply_patch(%{"op" => "add", "path" => path, "value" => value}, target, opts) do
    Add.apply(%Add{path: path, value: value}, target, opts)
  end

  defp do_apply_patch(%{"op" => "remove", "path" => path}, target, opts) do
    Remove.apply(%Remove{path: path}, target, opts)
  end

  defp do_apply_patch(%{"op" => "replace", "path" => path, "value" => value}, target, opts) do
    Replace.apply(%Replace{path: path, value: value}, target, opts)
  end

  defp do_apply_patch(%{"op" => "copy", "from" => from, "path" => path}, target, opts) do
    Copy.apply(%Copy{from: from, path: path}, target, opts)
  end

  defp do_apply_patch(%{"op" => "move", "from" => from, "path" => path}, target, opts) do
    Move.apply(%Move{from: from, path: path}, target, opts)
  end

  defp do_apply_patch(%{"op" => "test", "path" => path, "value" => value}, target, opts) do
    Test.apply(%Test{path: path, value: value}, target, opts)
  end

  defp do_apply_patch(json_patch, _target, _opts) do
    {:error, {:invalid_spec, json_patch}}
  end

  @doc """
  Apply a Jsonpatch or a list of Jsonpatches to a map or struct. In case of an error
  it will raise an exception. When a list is provided, the operations are applied in
  the order as they appear in the list.

  (See Jsonpatch.apply_patch/2 for more details)
  """
  @spec apply_patch!(t() | list(t()), target :: Types.json_container(), Types.opts()) ::
          Types.json_container()
  def apply_patch!(json_patch, target, opts \\ []) do
    case apply_patch(json_patch, target, opts) do
      {:ok, patched} -> patched
      {:error, _} = error -> raise JsonpatchException, error
    end
  end

  @doc """
  Creates a patch from the difference of a source map to a destination map or list.

  ## Options

    * `:ancestor_path` - Sets the initial ancestor path for the diff operation.
      Defaults to `""` (root). Useful when you need to diff starting from a nested path.
    * `:prepare_map` - A function that lets to customize maps and structs before diffing.
      Defaults to `fn map -> map end` (no-op). Useful when you need to customize
      how maps and structs are handled during the diff process. Example:

      ```elixir
      fn
        %Struct{field1: value1, field2: value2} -> %{field1: "\#{value1} - \#{value2}"}
        %OtherStruct{} = struct -> Map.take(struct, [:field1])
        map -> map
      end
      ```

  ## Examples

      iex> source = %{"name" => "Bob", "married" => false, "hobbies" => ["Elixir", "Sport", "Football"]}
      iex> destination = %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
      iex> Jsonpatch.diff(source, destination)
      [
        %{path: "/married", value: true, op: "replace"},
        %{path: "/hobbies/2", op: "remove"},
        %{path: "/hobbies/1", op: "remove"},
        %{path: "/hobbies/0", value: "Elixir!", op: "replace"},
        %{path: "/age", value: 33, op: "add"}
      ]

      iex> source = %{"a" => 1, "b" => 2}
      iex> destination = %{"a" => 3, "c" => 4}
      iex> Jsonpatch.diff(source, destination, ancestor_path: "/nested")
      [
        %{path: "/nested/b", op: "remove"},
        %{path: "/nested/c", value: 4, op: "add"},
        %{path: "/nested/a", value: 3, op: "replace"}
      ]
  """
  @spec diff(Types.json_container(), Types.json_container(), Types.opts_diff()) :: [Jsonpatch.t()]
  def diff(source, destination, opts \\ []) do
    opts =
      opts
      |> Keyword.update(:object_hash, nil, &make_safe_hash_fn/1)
      |> Keyword.validate!(
        ancestor_path: "",
        prepare_map: fn struct -> struct end,
        object_hash: nil
      )

    cond do
      is_map(source) and is_map(destination) ->
        do_map_diff(destination, source, opts[:ancestor_path], [], opts)

      is_list(source) and is_list(destination) ->
        do_list_diff(destination, source, opts[:ancestor_path], [], 0, opts)

      # type of value changed, eg set to nil
      source != destination ->
        destination = maybe_prepare_map(destination, opts)
        [%{op: "replace", path: opts[:ancestor_path], value: destination}]

      true ->
        []
    end
  end

  defguardp are_unequal_maps(val1, val2) when val1 != val2 and is_map(val2) and is_map(val1)
  defguardp are_unequal_lists(val1, val2) when val1 != val2 and is_list(val2) and is_list(val1)

  defp do_diff(dest, source, path, key, patches, opts) when are_unequal_lists(dest, source) do
    # uneqal lists, let's use a specialized function for that
    do_list_diff(dest, source, "#{path}/#{escape(key)}", patches, 0, opts)
  end

  defp do_diff(dest, source, path, key, patches, opts) when are_unequal_maps(dest, source) do
    # uneqal maps, let's use a specialized function for that
    do_map_diff(dest, source, "#{path}/#{escape(key)}", patches, opts)
  end

  defp do_diff(dest, source, path, key, patches, opts) when dest != source do
    # scalar values or change of type (map -> list etc), let's just make a replace patch
    value = maybe_prepare_map(dest, opts)
    [%{op: "replace", path: "#{path}/#{escape(key)}", value: value} | patches]
  end

  defp do_diff(_dest, _source, _path, _key, patches, _opts) do
    # no changes, return patches as is
    patches
  end

  defp do_map_diff(%{} = destination, %{} = source, ancestor_path, patches, opts) do
    # Convert structs to maps if prepare_map function is provided
    destination = maybe_prepare_map(destination, opts)
    source = maybe_prepare_map(source, opts)

    # entrypoint for map diff, let's convert the map to a list of {k, v} tuples
    destination
    |> Map.to_list()
    |> do_map_diff(source, ancestor_path, patches, [], opts)
  end

  defp do_map_diff([], source, ancestor_path, patches, checked_keys, _opts) do
    # The complete desination was check. Every key that is not in the list of
    # checked keys, must be removed.
    Enum.reduce(source, patches, fn {k, _}, patches ->
      if k in checked_keys do
        patches
      else
        [%{op: "remove", path: "#{ancestor_path}/#{escape(k)}"} | patches]
      end
    end)
  end

  defp do_map_diff([{key, val} | rest], source, ancestor_path, patches, checked_keys, opts) do
    # normal iteration through list of map {k, v} tuples. We track seen keys to later remove not seen keys.
    patches =
      case Map.fetch(source, key) do
        {:ok, source_val} ->
          do_diff(val, source_val, ancestor_path, key, patches, opts)

        :error ->
          value = maybe_prepare_map(val, opts)
          [%{op: "add", path: "#{ancestor_path}/#{escape(key)}", value: value} | patches]
      end

    # Diff next value of same level
    do_map_diff(rest, source, ancestor_path, patches, [key | checked_keys], opts)
  end

  defp do_list_diff(destination, source, ancestor_path, patches, idx, opts) do
    if opts[:object_hash] do
      do_hash_list_diff(destination, source, ancestor_path, patches, opts)
    else
      do_pairwise_list_diff(destination, source, ancestor_path, patches, idx, opts)
    end
  catch
    # happens if we've got a nil hash or we tried to hash a non-map
    :hash_not_implemented ->
      do_pairwise_list_diff(destination, source, ancestor_path, patches, idx, opts)
  end

  defp do_pairwise_list_diff(destination, source, ancestor_path, patches, idx, opts)

  defp do_pairwise_list_diff([], [], _path, patches, _idx, _opts), do: patches

  defp do_pairwise_list_diff([], [_item | source_rest], ancestor_path, patches, idx, opts) do
    # if we find any leftover items in source, we have to remove them
    patches = [%{op: "remove", path: "#{ancestor_path}/#{idx}"} | patches]
    do_pairwise_list_diff([], source_rest, ancestor_path, patches, idx + 1, opts)
  end

  defp do_pairwise_list_diff(items, [], ancestor_path, patches, idx, opts) do
    # we have to do it without recursion, because we have to keep the order of the items
    items
    |> Enum.map_reduce(idx, fn val, idx ->
      {%{op: "add", path: "#{ancestor_path}/#{idx}", value: maybe_prepare_map(val, opts)},
       idx + 1}
    end)
    |> elem(0)
    |> Kernel.++(patches)
  end

  defp do_pairwise_list_diff(
         [val | rest],
         [source_val | source_rest],
         ancestor_path,
         patches,
         idx,
         opts
       ) do
    # case when there's an item in both desitation and source. Let's just compare them
    patches = do_diff(val, source_val, ancestor_path, idx, patches, opts)
    do_pairwise_list_diff(rest, source_rest, ancestor_path, patches, idx + 1, opts)
  end

  defp do_hash_list_diff(destination, source, ancestor_path, patches, opts) do
    hash_fn = Keyword.fetch!(opts, :object_hash)

    {additions, modifications, removals} =
      greedy_find_additions_modifications_removals(
        List.to_tuple(destination),
        List.to_tuple(source),
        index_by(destination, hash_fn),
        index_by(source, hash_fn),
        hash_fn,
        ancestor_path,
        opts
      )

    List.flatten([removals, additions, modifications, patches])
  end

  # credo:disable-for-next-line
  defp greedy_find_additions_modifications_removals(
         dest,
         source,
         dest_map,
         source_map,
         hash_fn,
         path,
         opts,
         dest_idx \\ 0,
         source_idx \\ 0,
         additions \\ [],
         modifications \\ [],
         removals \\ []
       ) do
    cond do
      tuple_size(dest) == dest_idx ->
        # we're at the end of the destination tuple, let's remove all remaining source items
        removals = add_removals(source_idx, tuple_size(source) - 1, path, removals)
        {Enum.reverse(additions), modifications, removals}

      tuple_size(source) == source_idx ->
        # we're at the end of the source tuple, let's add all remaining destination items
        additions = add_additions(dest_idx, tuple_size(dest) - 1, path, dest, additions, opts)
        {Enum.reverse(additions), modifications, removals}

      true ->
        # we're in the middle of the tuples, let's find the next matching items
        dest_item = elem(dest, dest_idx)
        source_item = elem(source, source_idx)

        source_hash = hash_fn.(source_item)
        dest_hash = hash_fn.(dest_item)

        if source_hash == dest_hash do
          # same items, let's diff recursively and bump both indexes
          modifications = do_diff(dest_item, source_item, path, dest_idx, modifications, opts)

          greedy_find_additions_modifications_removals(
            dest,
            source,
            dest_map,
            source_map,
            hash_fn,
            path,
            opts,
            dest_idx + 1,
            source_idx + 1,
            additions,
            modifications,
            removals
          )
        else
          # different items, let's find index of destination item in source and vice versa
          {next_dest_idx, next_source_idx} =
            determine_next_idx(
              dest_idx,
              source_idx,
              Map.get(dest_map, source_hash),
              Map.get(source_map, dest_hash)
            )

          removals = add_removals(source_idx, next_source_idx - 1, path, removals)
          additions = add_additions(dest_idx, next_dest_idx - 1, path, dest, additions, opts)

          greedy_find_additions_modifications_removals(
            dest,
            source,
            dest_map,
            source_map,
            hash_fn,
            path,
            opts,
            next_dest_idx,
            next_source_idx,
            additions,
            modifications,
            removals
          )
        end
    end
  end

  # credo:disable-for-next-line
  defp determine_next_idx(d_idx, s_idx, next_d_idx, next_s_idx) do
    dest_found = next_d_idx != nil and next_d_idx > d_idx
    source_found = next_s_idx != nil and next_s_idx > s_idx
    source_closer = dest_found and source_found and next_s_idx - s_idx < next_d_idx - d_idx

    cond do
      # in case when we can jump to either of them, we want to jump to the closer one
      source_closer -> {d_idx, next_s_idx}
      # only source is found ahead, we have to do source jump
      next_d_idx == nil and source_found -> {d_idx, next_s_idx}
      # only dest is found ahead, we have to do dest jump
      next_s_idx == nil and dest_found -> {next_d_idx, s_idx}
      # neither is found ahead, we have to advance both indexes
      true -> {d_idx + 1, s_idx + 1}
    end
  end

  @compile {:inline, index_by: 2}
  defp index_by(list, hash_fn) do
    list
    |> Enum.reduce({%{}, 0}, fn item, {map, idx} ->
      # if we have a hash collision, we throw an error and handle as if the hash is not implemented
      {Map.update(map, hash_fn.(item), idx, fn _ -> throw(:hash_not_implemented) end), idx + 1}
    end)
    |> elem(0)
  end

  @compile {:inline, add_removals: 4}
  defp add_removals(from_idx, to_idx, path, removals) do
    Enum.reduce(from_idx..to_idx//1, removals, fn idx, removals ->
      [%{op: "remove", path: "#{path}/#{idx}"} | removals]
    end)
  end

  @compile {:inline, add_additions: 6}
  defp add_additions(from_idx, to_idx, path, dest_tuple, additions, opts) do
    Enum.reduce(from_idx..to_idx//1, additions, fn idx, additions ->
      value = dest_tuple |> elem(idx) |> maybe_prepare_map(opts)
      [%{op: "add", path: "#{path}/#{idx}", value: value} | additions]
    end)
  end

  @compile {:inline, maybe_prepare_map: 2}
  defp maybe_prepare_map(value, opts) when is_map(value) do
    prepare_fn = Keyword.fetch!(opts, :prepare_map)
    prepare_fn.(value)
  end

  defp maybe_prepare_map(value, _opts), do: value

  @compile {:inline, escape: 1}
  defp escape(fragment) when is_binary(fragment) do
    fragment =
      if :binary.match(fragment, "~") != :nomatch,
        do: String.replace(fragment, "~", "~0"),
        else: fragment

    if :binary.match(fragment, "/") != :nomatch,
      do: String.replace(fragment, "/", "~1"),
      else: fragment
  end

  defp escape(fragment), do: fragment

  defp make_safe_hash_fn(hash_fn) do
    # we want to compare only maps, and returning nil should mean
    # we should compare lists pairwise instead
    fn
      %{} = item ->
        case hash_fn.(item) do
          nil -> throw(:hash_not_implemented)
          hash -> hash
        end

      _item ->
        throw(:hash_not_implemented)
    end
  end
end
