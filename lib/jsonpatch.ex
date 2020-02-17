defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.
  """

  alias Jsonpatch.FlatMap

  @doc """
  Creates a patch from the difference of a source map to a target map.
  """
  @spec diff(map, map) :: {:error, nil} | {:ok, map}
  def diff(source, destination)


  def diff(%{} = source, %{} = destination) do
    source = FlatMap.parse(source)
    destination = FlatMap.parse(destination)

    []
    |> create_additions(source, destination)
  end

  def diff(_source, _target) do
    {:error, nil}
  end

  @doc """
  Creates "add"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_additions(list, map, map) :: {:error, nil} | {:ok, map}
  def create_additions(accumulator, source, destination)

  def create_additions(accumulator, %{} = source, %{} = destination) do
    additions = Map.keys(destination)
    |> Enum.filter(fn key -> not Map.has_key?(source, key) end)
    |> Enum.map(fn key -> %{"op" => "add", "path" => key, "value" => Map.get(destination, key)} end)

    {:ok, additions ++ accumulator}
  end

  def create_additions(_accumulator, _source, _target) do
    {:error, nil}
  end


  @doc """
  Possible, valid operations
  """
  @spec operations :: [<<_::24, _::_*8>>, ...]
  def operations do
    ["add", "remove", "replace", "move", "copy", "test"]
  end


  @doc """
  Validates if the given op is a valid operation.
  """
  @spec is_op(binary) :: boolean
  def is_op(op) do
    op in operations()
  end


  @doc """
  Validates an operation.
  """
  @spec validate_op(map) :: boolean
  def validate_op(operation)

  def validate_op(%{op: "add", path: path, value: value}), do: path != nil and value != nil
  def validate_op(%{op: "add"}), do: false

  def validate_op(%{op: "remove", path: path}), do: path != nil
  def validate_op(%{op: "remove"}), do: false

  def validate_op(%{op: "replace", path: path, value: value}), do: path != nil and value != nil
  def validate_op(%{op: "replace"}), do: false

  def validate_op(%{op: "move", from: from, path: path}), do: from != nil and path != nil
  def validate_op(%{op: "move"}), do: false

  def validate_op(%{op: "copy", from: from, path: path}), do: from != nil and path != nil
  def validate_op(%{op: "copy"}), do: false

  def validate_op(%{op: "test", path: path, value: value}), do: path != nil and value != nil
  def validate_op(%{op: "test"}), do: false
end
