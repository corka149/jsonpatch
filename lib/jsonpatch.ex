defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.

  The patch can be a single change or a list of things that shall be changed. Therefore
  a list or a single JSON patch can be provided. Every patch belongs to a certain operation
  which influences the usage.

  Accorrding to [RFC 6901](https://tools.ietf.org/html/rfc6901) escaping of `/` and `~` is done
  by using `~1` for `/` and `~0` for `~`.
  """

  alias Jsonpatch.Operation
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
  Apply a Jsonpatch to a map or struct. The whole patch will not be applied
  when any path is invalid or any other error occured.

  ## Examples
      iex> patch = [
      ...> %Jsonpatch.Operation.Add{path: "/age", value: 33},
      ...> %Jsonpatch.Operation.Replace{path: "/hobbies/0", value: "Elixir!"},
      ...> %Jsonpatch.Operation.Replace{path: "/married", value: true},
      ...> %Jsonpatch.Operation.Remove{path: "/hobbies/1"},
      ...> %Jsonpatch.Operation.Remove{path: "/hobbies/2"},
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
  @spec apply_patch(Jsonpatch.t() | list(Jsonpatch.t()), map()) ::
          {:ok, map()} | Jsonpatch.error()
  def apply_patch(json_patch, target)

  def apply_patch(json_patch, %{} = target) when is_list(json_patch) do
    # Operatons MUST be sorted before applying because a remove operation for path "/foo/2" must be done
    # before the remove operation for path "/foo/1". Without order it could be possible that the wrong
    # value will be removed or only one value instead of two.
    result =
      json_patch
      |> Enum.map(&create_sort_value/1)
      |> Enum.sort(fn {sort_value_1, _}, {sort_value_2, _} -> sort_value_1 >= sort_value_2 end)
      |> Enum.map(fn {_, patch} -> patch end)
      |> Enum.reduce(target, &Jsonpatch.Operation.apply_op/2)

    case result do
      {:error, _, _} = error -> error
      ok_result -> {:ok, ok_result}
    end
  end

  def apply_patch(json_patch, %{} = target) do
    result = Operation.apply_op(json_patch, target)

    case result do
      {:error, _, _} = error -> error
      ok_result -> {:ok, ok_result}
    end
  end

  @doc """
  Apply a Jsonpatch to a map or struct. In case of an error
  it will raise an exception.

  (See Jsonpatch.apply_patch/2 for more details)
  """
  @spec apply_patch!(Jsonpatch.t() | list(Jsonpatch.t()), map()) :: map()
  def apply_patch!(json_patch, target)

  def apply_patch!(json_patch, target) do
    case apply_patch(json_patch, target) do
      {:ok, patched} -> patched
      {:error, _, _} = error -> raise JsonpatchException, error
    end
  end

  @doc """
  Creates a patch from the difference of a source map to a target map.

  ## Examples

      iex> source = %{"name" => "Bob", "married" => false, "hobbies" => ["Elixir", "Sport", "Football"]}
      iex> destination = %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
      iex> Jsonpatch.diff(source, destination)
      [
        %Add{path: "/age", value: 33},
        %Replace{path: "/hobbies/0", value: "Elixir!"},
        %Replace{path: "/married", value: true},
        %Remove{path: "/hobbies/1"},
        %Remove{path: "/hobbies/2"}
      ]
  """
  @spec diff(maybe_improper_list | map, maybe_improper_list | map) :: list(Jsonpatch.t())
  def diff(source, destination)

  def diff(%{} = source, %{} = destination) do
    Map.to_list(destination)
    |> diff_adds_and_replaces(source, "")
  end

  def diff(source, destination) when is_list(source) and is_list(destination) do
    Enum.with_index(destination)
    |> Enum.map(fn {v, k} -> {k, v} end)
    |> diff_adds_and_replaces(source, "")
  end

  def diff(_, _) do
    []
  end

  # ===== ===== PRIVATE ===== =====

  defguardp are_unequal_maps(val1, val2)
            when val1 != val2 and is_map(val2) and is_map(val1)

  defguardp are_unequal_lists(val1, val2)
            when val1 != val2 and is_list(val2) and is_list(val1)

  defp diff_adds_and_replaces(target, source, current_path, acc \\ [])

  defp diff_adds_and_replaces([], _, _, acc) do
    acc
  end

  defp diff_adds_and_replaces([{key, val} | tail], source, ancestor_path, acc)
       when is_list(source) or is_map(source) do
    current_path = "#{ancestor_path}/#{escape(key)}"

    from_source =
      cond do
        is_map(source) -> Map.get(source, key)
        is_list(source) -> Enum.at(source, key)
      end

    acc =
      case from_source do
        # Key is not present in source
        nil ->
          [%Add{path: current_path, value: val} | acc]

        # Source has a different value but both (target and source) value are lists or a maps
        source_val
        when are_unequal_lists(source_val, val) or are_unequal_maps(source_val, val) ->
          # Enter next level
          diff_adds_and_replaces(next_level(val), source_val, current_path, acc)

        # Scalar source val that is not equal
        source_val when source_val != val ->
          [%Replace{path: current_path, value: val} | acc]

        _ ->
          acc
      end

    # Diff next value of same level
    diff_adds_and_replaces(tail, source, ancestor_path, acc)
  end

  # Transforms a map into a tuple list and a list also into a tuple list with indizes
  defp next_level(val) do
    cond do
      is_list(val) -> Enum.with_index(val) |> Enum.map(fn {v, k} -> {k, v} end)
      is_map(val) -> Map.to_list(val)
      true -> []
    end
  end

  # Escape `/` to `~1 and `~` to `~`.
  defp escape(subpath) when is_bitstring(subpath) do
    subpath
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
  end

  defp escape(subpath) do
    subpath
  end

  # Create once a easy sortable value for a operation
  defp create_sort_value(%{path: path} = operation) do
    fragments = String.split(path, "/")

    x = Jsonpatch.PathUtil.operation_sort_value?(operation) * 1_000_000 * 100_000_000
    y = length(fragments) * 100_000_000

    z =
      case List.last(fragments) |> Integer.parse() do
        :error -> 0
        {int, _} -> int
      end

    # Structure of recorde sort value
    # x = Kind of PathUtil
    # y = Amount of fragments (how deep goes the path?)
    # z = At which position in a list?
    # xxxxyyyyyyzzzzzzzz
    {x + y + z, operation}
  end
end
