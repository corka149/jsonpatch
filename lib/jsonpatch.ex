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
  """
  @spec diff(Types.json_container(), Types.json_container()) :: [Jsonpatch.t()]
  def diff(source, destination)

  def diff(%{} = source, %{} = destination) do
    do_map_diff(destination, source)
  end

  def diff(source, destination) when is_list(source) and is_list(destination) do
    do_list_diff(destination, source)
  end

  def diff(_, _) do
    []
  end

  defguardp are_unequal_maps(val1, val2) when val1 != val2 and is_map(val2) and is_map(val1)
  defguardp are_unequal_lists(val1, val2) when val1 != val2 and is_list(val2) and is_list(val1)

  defp do_diff(dest, source, path, key, patches) when are_unequal_lists(dest, source) do
    # uneqal lists, let's use a specialized function for that
    do_list_diff(dest, source, "#{path}/#{escape(key)}", patches)
  end

  defp do_diff(dest, source, path, key, patches) when are_unequal_maps(dest, source) do
    # uneqal maps, let's use a specialized function for that
    do_map_diff(dest, source, "#{path}/#{escape(key)}", patches)
  end

  defp do_diff(dest, source, path, key, patches) when dest != source do
    # scalar values or change of type (map -> list etc), let's just make a replace patch
    [%{op: "replace", path: "#{path}/#{escape(key)}", value: dest} | patches]
  end

  defp do_diff(_dest, _source, _path, _key, patches) do
    # no changes, return patches as is
    patches
  end

  defp do_map_diff(%{} = destination, %{} = source, ancestor_path \\ "", patches \\ []) do
    # entrypoint for map diff, let's convert the map to a list of {k, v} tuples
    destination
    |> Map.to_list()
    |> do_map_diff(source, ancestor_path, patches, [])
  end

  defp do_map_diff([], source, ancestor_path, patches, checked_keys) do
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

  defp do_map_diff([{key, val} | rest], source, ancestor_path, patches, checked_keys) do
    # normal iteration through list of map {k, v} tuples. We track seen keys to later remove not seen keys.
    patches =
      case Map.fetch(source, key) do
        {:ok, source_val} -> do_diff(val, source_val, ancestor_path, key, patches)
        :error -> [%{op: "add", path: "#{ancestor_path}/#{escape(key)}", value: val} | patches]
      end

    # Diff next value of same level
    do_map_diff(rest, source, ancestor_path, patches, [key | checked_keys])
  end

  defp do_list_diff(destination, source, ancestor_path \\ "", patches \\ [], idx \\ 0)

  defp do_list_diff([], [], _path, patches, _idx), do: patches

  defp do_list_diff([], [_item | source_rest], ancestor_path, patches, idx) do
    # if we find any leftover items in source, we have to remove them
    patches = [%{op: "remove", path: "#{ancestor_path}/#{idx}"} | patches]
    do_list_diff([], source_rest, ancestor_path, patches, idx + 1)
  end

  defp do_list_diff(items, [], ancestor_path, patches, idx) do
    # we have to do it without recursion, because we have to keep the order of the items
    items
    |> Enum.map_reduce(idx, fn val, idx ->
      {%{op: "add", path: "#{ancestor_path}/#{idx}", value: val}, idx + 1}
    end)
    |> elem(0)
    |> Kernel.++(patches)
  end

  defp do_list_diff([val | rest], [source_val | source_rest], ancestor_path, patches, idx) do
    # case when there's an item in both desitation and source. Let's just compare them
    patches = do_diff(val, source_val, ancestor_path, idx, patches)
    do_list_diff(rest, source_rest, ancestor_path, patches, idx + 1)
  end

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
end
