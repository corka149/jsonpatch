defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.

  The patch can be a single change or a list of things that shall be changed. Therefore
  a list or a single JSON patch can be provided. Every patch belongs to a certain operation
  which influences the usage.
  """

  alias Jsonpatch.FlatMap
  alias Jsonpatch.PathUtil.Add
  alias Jsonpatch.PathUtil.Copy
  alias Jsonpatch.PathUtil.Move
  alias Jsonpatch.PathUtil.Remove
  alias Jsonpatch.PathUtil.Replace
  alias Jsonpatch.PathUtil.Test

  @typedoc """
  A valid Jsonpatch operation by RFC 6902
  """
  @type t :: Add.t() | Remove.t() | Replace.t() | Copy.t() | Move.t() | Test.t()

  @doc """
  Apply a Jsonpatch to a map or struct. The whole patch will not be applied
  when any path is invalid or any other error occured.

  ## Examples
      iex> patch = [
      ...> %Jsonpatch.PathUtil.Add{path: "/age", value: 33},
      ...> %Jsonpatch.PathUtil.Replace{path: "/hobbies/0", value: "Elixir!"},
      ...> %Jsonpatch.PathUtil.Replace{path: "/married", value: true},
      ...> %Jsonpatch.PathUtil.Remove{path: "/hobbies/1"},
      ...> %Jsonpatch.PathUtil.Remove{path: "/hobbies/2"},
      ...> %Jsonpatch.PathUtil.Copy{from: "/name", path: "/surname"},
      ...> %Jsonpatch.PathUtil.Move{from: "/home", path: "/work"},
      ...> %Jsonpatch.PathUtil.Test{path: "/name", value: "Bob"}
      ...> ]
      iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
      iex> Jsonpatch.apply_patch(patch, target)
      %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33, "surname" => "Bob", "work" => "Berlin"}

      iex> # Patch will not be applied if test fails. The target will not be changed.
      iex> patch = [
      ...> %Jsonpatch.PathUtil.Add{path: "/age", value: 33},
      ...> %Jsonpatch.PathUtil.Test{path: "/name", value: "Alice"}
      ...> ]
      iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
      iex> Jsonpatch.apply_patch(patch, target)
      %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
  """
  @spec(
    apply_patch(Jsonpatch.t() | list(Jsonpatch.t()), map()) ::
      map(),
    Jsonpatch.t() | list(Jsonpatch.t())
  )
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
      |> Enum.reduce(target, &do_apply_patch/2)

    case result do
      :error -> target
      ok_result -> ok_result
    end
  end

  def apply_patch(%Add{} = json_patch, %{} = target) do
    Add.apply_op(json_patch, target)
  end

  def apply_patch(%Replace{} = json_patch, %{} = target) do
    Replace.apply_op(json_patch, target)
  end

  def apply_patch(%Remove{} = json_patch, %{} = target) do
    case Remove.apply_op(json_patch, target) do
      :error -> target
      update_val -> update_val
    end
  end

  def apply_patch(%Copy{} = json_patch, %{} = target) do
    case Copy.apply_op(json_patch, target) do
      :error -> target
      updated_val -> updated_val
    end
  end

  def apply_patch(%Move{} = json_patch, %{} = target) do
    case Move.apply_op(json_patch, target) do
      :error -> target
      updated_val -> updated_val
    end
  end

  def apply_patch(%Test{} = json_patch, %{} = target) do
    case Test.apply_op(json_patch, target) do
      :ok -> target
      :error -> :error
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
  @spec diff(map, map) :: list(Jsonpatch.t())
  def diff(source, destination)

  def diff(%{} = source, %{} = destination) do
    source = FlatMap.parse(source)
    destination = FlatMap.parse(destination)

    []
    |> create_additions(source, destination)
    |> create_replaces(source, destination)
    |> create_removes(source, destination)
  end

  @doc """
  Creates "add"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_additions(list(Jsonpatch.t()), map, map) :: list(Jsonpatch.t())
  def create_additions(accumulator \\ [], source, destination)

  def create_additions(accumulator, %{} = source, %{} = destination) do
    additions =
      Map.keys(destination)
      |> Enum.filter(fn key -> not Map.has_key?(source, key) end)
      |> Enum.map(fn key ->
        %Add{path: key, value: Map.get(destination, key)}
      end)

    accumulator ++ additions
  end

  @doc """
  Creates "remove"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_removes(list(Jsonpatch.t()), map, map) :: list(Jsonpatch.t())
  def create_removes(accumulator \\ [], source, destination)

  def create_removes(accumulator, %{} = source, %{} = destination) do
    removes =
      Map.keys(source)
      |> Enum.filter(fn key -> not Map.has_key?(destination, key) end)
      |> Enum.map(fn key -> %Remove{path: key} end)

    accumulator ++ removes
  end

  @doc """
  Creates "replace"-operations by comparing keys and values of source and destination. The source and
  destination map have to be flat maps.
  """
  @spec create_replaces(list(Jsonpatch.t()), map, map) :: list(Jsonpatch.t())
  def create_replaces(accumulator \\ [], source, destination)

  def create_replaces(accumulator, source, destination) do
    replaces =
      Map.keys(destination)
      |> Enum.filter(fn key -> Map.has_key?(source, key) end)
      |> Enum.filter(fn key -> Map.get(source, key) != Map.get(destination, key) end)
      |> Enum.map(fn key ->
        %Replace{path: key, value: Map.get(destination, key)}
      end)

    accumulator ++ replaces
  end

  # ===== ===== PRIVATE ===== =====

  defp do_apply_patch(%Add{} = json_patch, %{} = target) do
    Add.apply_op(json_patch, target)
  end

  defp do_apply_patch(%Replace{} = json_patch, %{} = target) do
    Replace.apply_op(json_patch, target)
  end

  defp do_apply_patch(%Remove{} = json_patch, %{} = target) do
    Remove.apply_op(json_patch, target)
  end

  defp do_apply_patch(%Copy{} = json_patch, %{} = target) do
    Copy.apply_op(json_patch, target)
  end

  defp do_apply_patch(%Move{} = json_patch, %{} = target) do
    Move.apply_op(json_patch, target)
  end

  defp do_apply_patch(%Test{} = json_patch, %{} = target) do
    case Test.apply_op(json_patch, target) do
      :ok -> target
      :error -> :error
    end
  end

  defp do_apply_patch(_json_patch, :error) do
    :error
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
