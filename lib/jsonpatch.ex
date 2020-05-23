defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.

  The patch can be a single change or a list of things that shall be changed. Therefore
  a list or a single JSON patch can be provided. Every patch belongs to a certain operation
  which influences the usage.
  """

  alias Jsonpatch.FlatMap
  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Copy
  alias Jsonpatch.Operation.Move
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace
  alias Jsonpatch.Operation.Test

  @doc """
  Apply a Jsonpatch to a map/struct.

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
      iex>
      iex> # Patch will not be applied if test fails. The target will not be changed.
      %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33, "surname" => "Bob", "work" => "Berlin"}
      iex> patch = [
      ...> %Add{path: "/age", value: 33},
      ...> %Test{path: "/name", value: "Alice"}
      ...> ]
      iex> target = %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
      iex> Jsonpatch.apply_patch(patch, target)
      %{"name" => "Bob", "married" => false, "hobbies" => ["Sport", "Elixir", "Football"], "home" => "Berlin"}
  """
  @spec apply_patch(Operation.t() | list(Operation.t()), map()) ::
          map(), Operation.t() | list(Operation.t())
  def apply_patch(json_patch, target)

  def apply_patch(json_patch, %{} = target) when is_list(json_patch) do
    # Operatons MUST be sorted before applying because a remove operation for path "/foo/2" must be done
    # before the remove operation for path "/foo/1". Without order it could be possible that the wrong
    # value will be removed or only one value instead of two.
    result = json_patch
    |> Enum.map(&create_sort_value/1)
    |> Enum.sort(fn {sort_value_1, _}, {sort_value_2, _} -> sort_value_1 >= sort_value_2 end)
    |> Enum.map(fn {_, patch} -> patch end)
    |> Enum.reduce(target, &apply_patch/2)

    case result do
      :error ->  target
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
    Remove.apply_op(json_patch, target)
  end

  def apply_patch(%Copy{} = json_patch, %{} = target) do
    Copy.apply_op(json_patch, target)
  end

  def apply_patch(%Move{} = json_patch, %{} = target) do
    Move.apply_op(json_patch, target)
  end

  def apply_patch(%Test{} = json_patch, %{} = target) do
    case Test.apply_op(json_patch, target)  do
      :ok ->  target
      :error -> :error
    end
  end

  def apply_patch(_json_patch, :error) do
    :error
  end

  @doc """
  Creates a patch from the difference of a source map to a target map.

  ## Examples

      iex> source = %{"name" => "Bob", "married" => false, "hobbies" => ["Elixir", "Sport", "Football"]}
      iex> destination = %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
      iex> Jsonpatch.diff(source, destination)
      {:ok, [
        %Add{path: "/age", value: 33},
        %Replace{path: "/hobbies/0", value: "Elixir!"},
        %Replace{path: "/married", value: true},
        %Remove{path: "/hobbies/1"},
        %Remove{path: "/hobbies/2"}
      ]}
  """
  @spec diff(map, map) :: {:error, nil} | {:ok, list(Operation.t())}
  def diff(source, destination)

  def diff(%{} = source, %{} = destination) do
    source = FlatMap.parse(source)
    destination = FlatMap.parse(destination)

    {:ok, []}
    |> additions(source, destination)
    |> replaces(source, destination)
    |> removes(source, destination)
  end

  def diff(_source, _target) do
    {:error, nil}
  end

  @doc """
  Creates "add"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_additions(list(Operation.t()), map, map) ::
          {:error, nil} | {:ok, list(Operation.t())}
  def create_additions(accumulator \\ [], source, destination)

  def create_additions(accumulator, %{} = source, %{} = destination) do
    additions =
      Map.keys(destination)
      |> Enum.filter(fn key -> not Map.has_key?(source, key) end)
      |> Enum.map(fn key ->
        %Add{path: key, value: Map.get(destination, key)}
      end)

    {:ok, accumulator ++ additions}
  end

  @doc """
  Creates "remove"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_removes(list(Operation.t()), map, map) ::
          {:error, nil} | {:ok, list(Operation.t())}
  def create_removes(accumulator \\ [], source, destination)

  def create_removes(accumulator, %{} = source, %{} = destination) do
    removes =
      Map.keys(source)
      |> Enum.filter(fn key -> not Map.has_key?(destination, key) end)
      |> Enum.map(fn key -> %Remove{path: key} end)

    {:ok, accumulator ++ removes}
  end

  @doc """
  Creates "replace"-operations by comparing keys and values of source and destination. The source and
  destination map have to be flat maps.
  """
  @spec create_replaces(list(Operation.t()), map, map) ::
          {:error, nil} | {:ok, list(Operation.t())}
  def create_replaces(accumulator \\ [], source, destination)

  def create_replaces(accumulator, source, destination) do
    replaces =
      Map.keys(destination)
      |> Enum.filter(fn key -> Map.has_key?(source, key) end)
      |> Enum.filter(fn key -> Map.get(source, key) != Map.get(destination, key) end)
      |> Enum.map(fn key ->
        %Replace{path: key, value: Map.get(destination, key)}
      end)

    {:ok, accumulator ++ replaces}
  end

  # ===== ===== PRIVATE ===== =====

  defp additions({:ok, accumulator}, source, destination) when is_list(accumulator) do
    create_additions(accumulator, source, destination)
  end

  defp removes({:ok, accumulator}, source, destination) when is_list(accumulator) do
    create_removes(accumulator, source, destination)
  end

  defp replaces({:ok, accumulator}, source, destination) when is_list(accumulator) do
    create_replaces(accumulator, source, destination)
  end

  # Create once a easy sortable value for a operation
  defp create_sort_value(%{path: path} = operation) do
    fragments = String.split(path, "/")

    x = Jsonpatch.Operation.operation_sort_value?(operation) * 1_000_000 * 100_000_000
    y = length(fragments) * 100_000_000

    z =
      case List.last(fragments) |> Integer.parse() do
        :error -> 0
        {int, _} -> int
      end

    # Structure of recorde sort value
    # x = Kind of Operation
    # y = Amount of fragments (how deep goes the path?)
    # z = At which position in a list?
    # xxxxyyyyyyzzzzzzzz
    {x + y + z, operation}
  end
end
