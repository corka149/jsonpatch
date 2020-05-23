defmodule Jsonpatch.Mapper do
  @moduledoc """
  Maps JSON patches between regular maps and Jsonpatch.Operations.
  """

  @spec to_map(Jsonpatch.Operation.t() | list(Jsonpatch.Operation.t())) ::
          map() | {:error, :invalid}
  def to_map(patch)

  def to_map(patch_operations) when is_list(patch_operations) do
    Enum.map(patch_operations, &prepare/1)
    |> Enum.filter(&is_valid/1)
  end

  def to_map(%{} = patch_operation) do
    case prepare(patch_operation) do
      {:error, _} = error -> error
      patch -> patch
    end
  end

  @doc """
  Creates JSON patch struct/s from a single or list maps which represents JSON patches.

  ## Examples

      iex> add_patch_map = %{"op" => "add", "path" => "/name", "value" => "Alice"}
      iex> Jsonpatch.Mapper.from_map(add_patch_map)
      %Jsonpatch.Operation.Add{path: "/name", value: "Alice"}

      iex> unkown_patch_map = %{"op" => "foo", "path" => "/name", "value" => "Alice"}
      iex> Jsonpatch.Mapper.from_map(unkown_patch_map)
      {:error, :invalid}
  """
  @spec from_map(map() | list(map())) ::
          list(Jsonpatch.Operation.t()) | Jsonpatch.Operation.t() | {:error, :invalid}
  def from_map(patch)

  def from_map(%{} = patch) do
    convert_to(patch)
  end

  def from_map(patch) when is_list(patch) do
    Enum.map(patch, &from_map/1)
  end

  # ===== ===== PRIVATE ===== =====

  defp prepare(%Jsonpatch.Operation.Add{} = operation) do
    Map.put(operation, :op, "add")
  end

  defp prepare(%Jsonpatch.Operation.Remove{} = operation) do
    Map.put(operation, :op, "remove")
  end

  defp prepare(%Jsonpatch.Operation.Replace{} = operation) do
    Map.put(operation, :op, "replace")
  end

  defp prepare(%Jsonpatch.Operation.Copy{} = operation) do
    Map.put(operation, :op, "copy")
  end

  defp prepare(%Jsonpatch.Operation.Move{} = operation) do
    Map.put(operation, :op, "move")
  end

  defp prepare(%Jsonpatch.Operation.Test{} = operation) do
    Map.put(operation, :op, "test")
  end

  defp prepare(_) do
    {:error, :invalid}
  end

  defp convert_to(json_patch) when is_list(json_patch) do
    Enum.map(json_patch, fn patch_part -> convert_to(patch_part) end)
  end

  defp convert_to(%{"op" => "add", "path" => path, "value" => value}) do
    %Jsonpatch.Operation.Add{path: path, value: value}
  end

  defp convert_to(%{"op" => "remove", "path" => path}) do
    %Jsonpatch.Operation.Remove{path: path}
  end

  defp convert_to(%{"op" => "replace", "path" => path, "value" => value}) do
    %Jsonpatch.Operation.Replace{path: path, value: value}
  end

  defp convert_to(%{"op" => "copy", "from" => from, "path" => path}) do
    %Jsonpatch.Operation.Copy{from: from, path: path}
  end

  defp convert_to(%{"op" => "move", "from" => from, "path" => path}) do
    %Jsonpatch.Operation.Move{from: from, path: path}
  end

  defp convert_to(%{"op" => "test", "path" => path, "value" => value}) do
    %Jsonpatch.Operation.Test{path: path, value: value}
  end

  defp convert_to(_) do
    {:error, :invalid}
  end

  defp is_valid({:error, _}), do: false
  defp is_valid(_), do: true
end
