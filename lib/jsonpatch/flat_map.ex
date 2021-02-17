defmodule Jsonpatch.FlatMap do
  @moduledoc false

  # ===== Internal documentation =====
  # Forms structs in a flat format with paths instead of nested maps/structs.

  @doc ~S"""
  Parses any map with/out arrays to a flat map.

  ## Examples

      iex> source = %{"a" => "b", "c" => ["d", "f"], "g" => %{"h" => "i"}}
      iex> Jsonpatch.FlatMap.parse(source)
      %{"/a" => "b", "/c/0" => "d", "/c/1" => "f", "/g/h" => "i"}

  """
  @spec parse(map) :: map
  def parse(source)

  # Break Map apart
  def parse(%{} = source) do
    flat(Map.to_list(source))
  end

  # ===== ===== PRIVATE ===== =====

  @spec flat(list, map, binary) :: map
  defp flat(source, accumulator \\ %{}, path \\ "")

  defp flat([], accumulator, _path) do
    # Empty list is source - nothing to add here
    accumulator
  end

  defp flat([{subpath, %{} = value} | tail], accumulator, path) do
    # Break the map in pieces & transform it
    accumulator = flat(Map.to_list(value), accumulator, "#{path}/#{subpath}")
    flat(tail, accumulator, path)
  end

  defp flat([{subpath, values} | tail], accumulator, path) when is_list(values) do
    # Break list in pieces & transform it
    accumulator =
      Enum.with_index(values)
      |> Enum.map(fn {v, p} -> {p, v} end)
      |> flat(accumulator, "#{path}/#{subpath}")

    flat(tail, accumulator, path)
  end

  defp flat([{subpath, value} | tail], accumulator, path) do
    subpath = escape(subpath)

    # Merge the stuff into the flat map
    accumulator = Map.merge(%{"#{path}/#{subpath}" => value}, accumulator)
    flat(tail, accumulator, path)
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
end
