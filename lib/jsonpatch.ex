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
  alias Jsonpatch.Utils

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
      ...> %Jsonpatch.Operation.Add{path: "/age", value: 33},
      ...> %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
      ...> %Jsonpatch.Operation.Replace{path: "/married", value: true},
      ...> %Jsonpatch.Operation.Remove{path: "/hobbies/2"},
      ...> %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
      ...> %Jsonpatch.Operation.Copy{from: "/name", path: "/surname"},
      ...> %Jsonpatch.Operation.Move{from: "/home", path: "/work"},
      ...> %Jsonpatch.Operation.Test{path: "/name", value: "Bob"}
      ...> ]
      iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
      iex> Jsonpatch.apply_patch(patch, target)
      {:ok, %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33, "surname" => "Bob", "work" => "Berlin"}}

      iex> # Patch will not be applied if test fails. The target will not be changed.
      iex> patch = [
      ...> %Jsonpatch.Operation.Add{path: "/age", value: 33},
      ...> %Jsonpatch.Operation.Test{path: "/name", value: "Alice"}
      ...> ]
      iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
      iex> Jsonpatch.apply_patch(patch, target)
      {:error, %Jsonpatch.Error{patch: %{"op" => "test", "path" => "/name", "value" => "Alice"}, patch_index: 1, reason: {:test_failed, "Expected value '\\"Alice\\"' at '/name'"}}}
  """
  @spec apply_patch(t() | [t()], target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | {:error, Jsonpatch.Error.t()}
  def apply_patch(json_patch, target, opts \\ []) do
    # https://datatracker.ietf.org/doc/html/rfc6902#section-3
    # > Operations are applied sequentially in the order they appear in the array.
    json_patch
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, target}, fn {patch, patch_index}, {:ok, acc} ->
      patch = cast_to_op_map(patch)

      case do_apply_patch(patch, acc, opts) do
        {:error, reason} ->
          error = %Jsonpatch.Error{patch: patch, patch_index: patch_index, reason: reason}
          {:halt, {:error, error}}

        {:ok, res} ->
          {:cont, {:ok, res}}
      end
    end)
  end

  defp cast_to_op_map(%struct_mod{} = json_patch) do
    json_patch =
      json_patch
      |> Map.from_struct()

    op =
      case struct_mod do
        Jsonpatch.Operation.Add -> "add"
        Jsonpatch.Operation.Remove -> "remove"
        Jsonpatch.Operation.Replace -> "replace"
        Jsonpatch.Operation.Copy -> "copy"
        Jsonpatch.Operation.Move -> "move"
        Jsonpatch.Operation.Test -> "test"
      end

    json_patch = Map.put(json_patch, "op", op)

    cast_to_op_map(json_patch)
  end

  defp cast_to_op_map(json_patch) do
    Map.new(json_patch, fn {k, v} -> {to_string(k), v} end)
  end

  defp do_apply_patch(%{"op" => "add", "path" => path, "value" => value}, target, opts) do
    Jsonpatch.Operation.Add.apply(%Add{path: path, value: value}, target, opts)
  end

  defp do_apply_patch(%{"op" => "remove", "path" => path}, target, opts) do
    Jsonpatch.Operation.Remove.apply(%Remove{path: path}, target, opts)
  end

  defp do_apply_patch(%{"op" => "replace", "path" => path, "value" => value}, target, opts) do
    Jsonpatch.Operation.Replace.apply(%Replace{path: path, value: value}, target, opts)
  end

  defp do_apply_patch(%{"op" => "copy", "from" => from, "path" => path}, target, opts) do
    Jsonpatch.Operation.Copy.apply(%Copy{from: from, path: path}, target, opts)
  end

  defp do_apply_patch(%{"op" => "move", "from" => from, "path" => path}, target, opts) do
    Jsonpatch.Operation.Move.apply(%Move{from: from, path: path}, target, opts)
  end

  defp do_apply_patch(%{"op" => "test", "path" => path, "value" => value}, target, opts) do
    Jsonpatch.Operation.Test.apply(%Test{path: path, value: value}, target, opts)
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
        %Jsonpatch.Operation.Replace{path: "/married", value: true},
        %Jsonpatch.Operation.Remove{path: "/hobbies/2"},
        %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
        %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
        %Jsonpatch.Operation.Add{path: "/age", value: 33}
      ]
  """
  @spec diff(Types.json_container(), Types.json_container()) :: [Jsonpatch.t()]
  def diff(source, destination)

  def diff(%{} = source, %{} = destination) do
    flat(destination)
    |> do_diff(source, "")
  end

  def diff(source, destination) when is_list(source) and is_list(destination) do
    flat(destination)
    |> do_diff(source, "")
  end

  def diff(_, _) do
    []
  end

  defguardp are_unequal_maps(val1, val2)
            when val1 != val2 and is_map(val2) and is_map(val1)

  defguardp are_unequal_lists(val1, val2)
            when val1 != val2 and is_list(val2) and is_list(val1)

  # Diff reduce loop
  defp do_diff(destination, source, ancestor_path, acc \\ [], checked_keys \\ [])

  defp do_diff([], source, ancestor_path, patches, checked_keys) do
    # The complete desination was check. Every key that is not in the list of
    # checked keys, must be removed.
    source
    |> flat()
    |> Stream.map(fn {k, _} -> escape(k) end)
    |> Stream.filter(fn k -> k not in checked_keys end)
    |> Stream.map(fn k -> %Remove{path: "#{ancestor_path}/#{k}"} end)
    |> Enum.reduce(patches, fn remove_patch, patches -> [remove_patch | patches] end)
  end

  defp do_diff([{key, val} | tail], source, ancestor_path, patches, checked_keys) do
    current_path = "#{ancestor_path}/#{escape(key)}"

    patches =
      case Utils.fetch(source, key) do
        # Key is not present in source
        {:error, _} ->
          [%Add{path: current_path, value: val} | patches]

        # Source has a different value but both (destination and source) value are lists or a maps
        {:ok, source_val} when are_unequal_lists(source_val, val) ->
          val |> flat() |> Enum.reverse() |> do_diff(source_val, current_path, patches, [])

        {:ok, source_val} when are_unequal_maps(source_val, val) ->
          # Enter next level - set check_keys to empty list because it is a different level
          val |> flat() |> do_diff(source_val, current_path, patches, [])

        # Scalar source val that is not equal
        {:ok, source_val} when source_val != val ->
          [%Replace{path: current_path, value: val} | patches]

        _ ->
          patches
      end

    # Diff next value of same level
    do_diff(tail, source, ancestor_path, patches, [escape(key) | checked_keys])
  end

  # Transforms a map into a tuple list and a list also into a tuple list with indizes
  defp flat(val) when is_list(val),
    do: Stream.with_index(val) |> Enum.map(fn {v, k} -> {k, v} end)

  defp flat(val) when is_map(val),
    do: Map.to_list(val)

  defp escape(fragment) when is_binary(fragment), do: Utils.escape(fragment)
  defp escape(fragment) when is_integer(fragment), do: fragment
end
