defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.

  The patch can be a single change or a list of things that shall be changed. Therefore
  a list or a single JSON patch can be provided. Every patch belongs to a certain operation
  which influences the usage.

  According to [RFC 6901](https://tools.ietf.org/html/rfc6901) escaping of `/` and `~` is done
  by using `~1` for `/` and `~0` for `~`.
  """

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Copy
  alias Jsonpatch.Operation.Move
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace
  alias Jsonpatch.Operation.Test

  @typedoc """
  A valid Jsonpatch operation by RFC 6902
  """
  @type t :: Add.t() | Remove.t() | Replace.t() | Copy.t() | Move.t() | Test.t()

  @typedoc """
  Describe an error that occured while patching.
  """
  @type error :: {:error, :invalid_path | :invalid_index | :test_failed, bitstring()}

  @doc """
  Apply a Jsonpatch or a list of Jsonpatches to a map or struct. The whole patch will not be applied
  when any path is invalid or any other error occured. When a list is provided, the operations are
  applied in the order as they appear in the list.

  Atoms are never garbage collected. Therefore, `Jsonpatch` works by default only with maps
  which used binary strings as key. This behaviour can be controlled via the `:keys` option.

  ## Options
    * `:keys` - controls how parts of paths are decoded. Possible values:
      * `:strings` (default) - decodes parts of paths as binary strings,
      * `:atoms` - parts of paths are converted to atoms using `String.to_atom/1`,
      * `:atoms!` - parts of paths are converted to atoms using `String.to_existing_atom/1`

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
      {:error, :test_failed, "Expected value 'Alice' at '/name'"}
  """
  @spec apply_patch(Jsonpatch.t() | list(Jsonpatch.t()), map(), keyword()) ::
          {:ok, map()} | Jsonpatch.error()
  def apply_patch(json_patch, target, opts \\ [])

  def apply_patch(json_patch, target, opts) when is_list(json_patch) do
    # https://datatracker.ietf.org/doc/html/rfc6902#section-3
    # > Operations are applied sequentially in the order they appear in the array.
    result =
      Enum.reduce_while(json_patch, target, fn patch, acc ->
        case Jsonpatch.Operation.apply_op(patch, acc, opts) do
          {:error, _, _} = error -> {:halt, error}
          result -> {:cont, result}
        end
      end)

    case result do
      {:error, _, _} = error -> error
      ok_result -> {:ok, ok_result}
    end
  end

  def apply_patch(json_patch, target, opts) do
    apply_patch([json_patch], target, opts)
  end

  @doc """
  Apply a Jsonpatch or a list of Jsonpatches to a map or struct. In case of an error
  it will raise an exception. When a list is provided, the operations are applied in
  the order as they appear in the list.

  (See Jsonpatch.apply_patch/2 for more details)
  """
  @spec apply_patch!(Jsonpatch.t() | list(Jsonpatch.t()), map(), keyword()) :: map()
  def apply_patch!(json_patch, target, opts \\ [])

  def apply_patch!(json_patch, target, opts) do
    case apply_patch(json_patch, target, opts) do
      {:ok, patched} -> patched
      {:error, _, _} = error -> raise JsonpatchException, error
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
  @spec diff(maybe_improper_list | map, maybe_improper_list | map) :: list(Jsonpatch.t())
  def diff(source, destination)

  def diff(%{} = source, %{} = destination) do
    Map.to_list(destination)
    |> do_diff(source, "")
  end

  def diff(source, destination) when is_list(source) and is_list(destination) do
    Enum.with_index(destination)
    |> Enum.map(fn {v, k} -> {k, v} end)
    |> do_diff(source, "")
  end

  def diff(_, _) do
    []
  end

  # ===== ===== PRIVATE ===== =====

  # Helper for better readability
  defguardp are_unequal_maps(val1, val2)
            when val1 != val2 and is_map(val2) and is_map(val1)

  # Helper for better readability
  defguardp are_unequal_lists(val1, val2)
            when val1 != val2 and is_list(val2) and is_list(val1)

  # Diff reduce loop
  defp do_diff(destination, source, ancestor_path, acc \\ [], checked_keys \\ [])

  defp do_diff([], source, ancestor_path, acc, checked_keys) do
    # The complete desination was check. Every key that is not in the list of
    # checked keys, must be removed.
    acc =
      source
      |> flat()
      |> Stream.map(fn {k, _} -> k end)
      |> Stream.filter(fn k -> k not in checked_keys end)
      |> Stream.map(fn k -> %Remove{path: "#{ancestor_path}/#{k}"} end)
      |> Enum.reduce(acc, fn r, acc -> [r | acc] end)

    acc
  end

  defp do_diff([{key, val} | tail], source, ancestor_path, acc, checked_keys)
       when is_list(source) or is_map(source) do
    current_path = "#{ancestor_path}/#{escape(key)}"

    acc =
      case get(source, key) do
        # Key is not present in source
        nil ->
          [%Add{path: current_path, value: val} | acc]

        # Source has a different value but both (destination and source) value are lists or a maps
        source_val when are_unequal_lists(source_val, val) ->
          val |> flat() |> Enum.reverse() |> do_diff(source_val, current_path, acc, [])

        source_val when are_unequal_maps(source_val, val) ->
          # Enter next level - set check_keys to empty list because it is a different level
          val |> flat() |> do_diff(source_val, current_path, acc, [])

        # Scalar source val that is not equal
        source_val when source_val != val ->
          [%Replace{path: current_path, value: val} | acc]

        _ ->
          acc
      end

    # Diff next value of same level
    do_diff(tail, source, ancestor_path, acc, [escape(key) | checked_keys])
  end

  # Transforms a map into a tuple list and a list also into a tuple list with indizes
  defp flat(val) when is_list(val) do
    Stream.with_index(val) |> Enum.map(fn {v, k} -> {k, v} end)
  end

  defp flat(val) when is_map(val) do
    Map.to_list(val)
  end

  # Unified access to lists or maps
  defp get(source, key) when is_list(source) do
    Enum.at(source, key)
  end

  defp get(source, key) when is_map(source) do
    Map.get(source, key)
  end

  # Escape `/` to `~1 and `~` to `~0`.
  defp escape(subpath) when is_bitstring(subpath) do
    subpath
    |> do_escape("~", "~0")
    |> do_escape("/", "~1")
  end

  defp escape(subpath) do
    subpath
  end

  defp do_escape(subpath, pattern, replacement) do
    case String.contains?(subpath, pattern) do
      true -> String.replace(subpath, pattern, replacement)
      false -> subpath
    end
  end
end
