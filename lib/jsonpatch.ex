defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.
  """

  alias Jsonpatch.FlatMap
  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace

  @typedoc """
  A valid Jsonpatch operation by RFC 6902
  """
  @type operation :: Add.t() | Remove.t() | Replace.t()

  @doc """
  Creates a patch from the difference of a source map to a target map.
  """
  @spec diff(map, map) :: {:error, nil} | {:ok, list(operation())}
  def diff(source, destination)


  def diff(%{} = source, %{} = destination) do
    source = FlatMap.parse(source)
    destination = FlatMap.parse(destination)

    {:ok, []}
    |> create_additions(source, destination)
    |> create_removes(source, destination)
    |> create_replaces(source, destination)
  end

  def diff(_source, _target) do
    {:error, nil}
  end

  @doc """
  Creates "add"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_additions({:error, nil} | {:ok, list(operation())}, map, map) :: {:error, nil} | {:ok, list(operation())}
  def create_additions(accumulator, source, destination)

  def create_additions({:ok, accumulator}, %{} = source, %{} = destination) do
    additions = Map.keys(destination)
    |> Enum.filter(fn key -> not Map.has_key?(source, key) end)
    |> Enum.map(fn key -> %Add{path: key, value: Map.get(destination, key)} end)

    {:ok, accumulator ++ additions}
  end

  def create_additions(_accumulator, _source, _target) do
    {:error, nil}
  end

  @doc """
  Creates "remove"-operations by using the keys of the destination and check their existence in the
  source map. Source and destination has to be parsed to a flat map.
  """
  @spec create_removes({:error, nil} | {:ok, list(operation())}, map, map) :: {:error, nil} | {:ok, list(operation())}
  def create_removes(accumulator, source, destination)

  def create_removes({:ok, accumulator}, %{} = source, %{} = destination) do
    removes = Map.keys(source)
    |> Enum.filter(fn key -> not Map.has_key?(destination, key) end)
    |> Enum.map(fn key -> %Remove{path: key} end)

    {:ok, accumulator ++ removes}
  end

  def create_removes(_accumulator, _source, _target) do
    {:error, nil}
  end

  @doc """
  Creates "replace"-operations by comparing keys and values of source and destination. The source and
  destination map have to be flat maps.
  """
  @spec create_replaces({:error, nil} | {:ok, list(operation())}, map, map) :: {:error, nil} | {:ok, list(operation())}
  def create_replaces(accumulator, source, destination)

  def create_replaces({:ok, accumulator}, source, destination) do
    replaces = Map.keys(destination)
    |> Enum.filter(fn key -> Map.has_key?(source, key) end)
    |> Enum.filter(fn key -> Map.get(source, key) != Map.get(destination, key) end)
    |> Enum.map(fn key -> %Replace{path: key, value: Map.get(destination, key)} end)

    {:ok, accumulator ++ replaces}
  end

  def create_replaces(_accumulator, _source, _destination) do
    {:error, nil}
  end

end
