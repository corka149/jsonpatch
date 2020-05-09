defmodule Jsonpatch.FlatMap do
  @moduledoc """
  Forms structs in a flat format with paths instead of nested maps/structs.
  """

  @doc ~S"""
  Parses any map with/out arrays to a flat map.

  ## Examples

      iex> source = %{"a" => "b", "c" => ["d", "f"], "g" => %{"h" => "i"}}
      iex> Jsonpatch.FlatMap.parse(source)
      %{"/a" => "b", "/c/0" => "d", "/c/1" => "f", "/g/h" => "i"}

  """
  @spec parse(map) :: map
  def parse(source)

  def parse(%{} = source) do
    flat(Map.to_list(source))
  end

  # ===== ===== PRIVATE ===== =====

  @spec flat(list, map, binary) :: map
  defp flat(source, accumulator \\ %{}, path \\ "")

  defp flat([], accumulator, _path) do
    accumulator
  end

  defp flat([{subpath, %{} = value} | tail], accumulator, path) do
    accumulator = flat(Map.to_list(value), accumulator, "#{path}/#{subpath}")
    flat(tail, accumulator, path)
  end

  defp flat([{subpath, values} | tail], accumulator, path) when is_list(values) do
    accumulator =
      Enum.with_index(values)
      |> Enum.map(fn {v, p} -> {p, v} end)
      |> flat(accumulator, "#{path}/#{subpath}")

    flat(tail, accumulator, path)
  end

  defp flat([{subpath, value} | tail], accumulator, path) do
    accumulator = Map.merge(%{"#{path}/#{subpath}" => value}, accumulator)
    flat(tail, accumulator, path)
  end
end
