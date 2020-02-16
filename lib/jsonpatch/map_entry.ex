defmodule Jsonpatch.MapEntry do
  @doc """
  Forms structs in a flat format with paths instead of nested maps/structs.
  """

  alias Jsonpatch.MapEntry

  @enforce_keys [:path, :value]
  defstruct [:path, :value]

  @spec to_map_entries(map) :: [MapEntry.t()]
  def to_map_entries(source)

  def to_map_entries(%{} = source) do
    flat(Map.to_list(source))
  end

  # ===== ===== PRIVATE ===== =====

  @spec flat(list, [MapEntry.t()], binary) :: [MapEntry.t()]
  defp flat(source, accumulator \\ [], path \\ "/")

  defp flat([], accumulator, _path) do
    accumulator
  end

  defp flat([{subpath, value} | tail], accumulator, path) do
    accumulator = [%MapEntry{path: path <> subpath, value: value} | accumulator]
    flat(tail, accumulator, path)
  end
end
