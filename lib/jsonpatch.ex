defmodule Jsonpatch do
  @moduledoc """
  A implementation of [RFC 6902](https://tools.ietf.org/html/rfc6902) in pure Elixir.
  """

  @doc """
  Creates a diff from a source map to a target map.
  """
  @spec diff(map, map, binary) :: {:error, nil} | {:ok, map}
  def diff(source, destination, path \\ "/")

  def diff(%{} = source, %{} = destination, path) do
    {:ok, %{}}
  end

  def diff(_source, _target, _path) do
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
