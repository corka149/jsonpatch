defmodule Jsonpatch.Mapper do
  @moduledoc """
  Maps JSON patches between regular maps and Jsonpatch.PathUtils.
  """

  @doc """
  Turns JSON patches into regular map/s.

  ## Examples

      iex> add_patch_map = %Jsonpatch.PathUtil.Add{path: "/name", value: "Alice"}
      iex> Jsonpatch.Mapper.to_map(add_patch_map)
      %{op: "add", path: "/name", value: "Alice"}

  """
  @spec to_map(Jsonpatch.t() | list(Jsonpatch.t())) ::
          map() | {:error, :invalid}
  def to_map(patch)

  def to_map(patch_operations) when is_list(patch_operations) do
    Enum.map(patch_operations, &prepare/1)
    |> Enum.filter(&is_valid/1)
  end

  def to_map(%{} = patch_operation) do
    case prepare(patch_operation) do
      {:error, _} = error -> error
      patch -> patch |> Map.from_struct()
    end
  end

  @doc """
  Creates JSON patch struct/s from a single or list maps which represents JSON patches.

  ## Examples

      iex> add_patch_map = %{"op" => "add", "path" => "/name", "value" => "Alice"}
      iex> Jsonpatch.Mapper.from_map(add_patch_map)
      %Jsonpatch.PathUtil.Add{path: "/name", value: "Alice"}

      iex> unkown_patch_map = %{"op" => "foo", "path" => "/name", "value" => "Alice"}
      iex> Jsonpatch.Mapper.from_map(unkown_patch_map)
      {:error, :invalid}
  """
  @spec from_map(map() | list(map())) ::
          list(Jsonpatch.t()) | Jsonpatch.t() | {:error, :invalid}
  def from_map(patch)

  def from_map(%{} = patch) do
    convert_to(patch)
  end

  def from_map(patch) when is_list(patch) do
    Enum.map(patch, &from_map/1)
  end

  # ===== ===== PRIVATE ===== =====

  defp prepare(%Jsonpatch.PathUtil.Add{} = operation) do
    Map.put(operation, :op, "add")
  end

  defp prepare(%Jsonpatch.PathUtil.Remove{} = operation) do
    Map.put(operation, :op, "remove")
  end

  defp prepare(%Jsonpatch.PathUtil.Replace{} = operation) do
    Map.put(operation, :op, "replace")
  end

  defp prepare(%Jsonpatch.PathUtil.Copy{} = operation) do
    Map.put(operation, :op, "copy")
  end

  defp prepare(%Jsonpatch.PathUtil.Move{} = operation) do
    Map.put(operation, :op, "move")
  end

  defp prepare(%Jsonpatch.PathUtil.Test{} = operation) do
    Map.put(operation, :op, "test")
  end

  defp prepare(_) do
    {:error, :invalid}
  end

  defp convert_to(json_patch) when is_list(json_patch) do
    Enum.map(json_patch, fn patch_part -> convert_to(patch_part) end)
  end

  defp convert_to(%{"op" => "add", "path" => path, "value" => value}) do
    %Jsonpatch.PathUtil.Add{path: path, value: value}
  end

  defp convert_to(%{"op" => "remove", "path" => path}) do
    %Jsonpatch.PathUtil.Remove{path: path}
  end

  defp convert_to(%{"op" => "replace", "path" => path, "value" => value}) do
    %Jsonpatch.PathUtil.Replace{path: path, value: value}
  end

  defp convert_to(%{"op" => "copy", "from" => from, "path" => path}) do
    %Jsonpatch.PathUtil.Copy{from: from, path: path}
  end

  defp convert_to(%{"op" => "move", "from" => from, "path" => path}) do
    %Jsonpatch.PathUtil.Move{from: from, path: path}
  end

  defp convert_to(%{"op" => "test", "path" => path, "value" => value}) do
    %Jsonpatch.PathUtil.Test{path: path, value: value}
  end

  defp convert_to(_) do
    {:error, :invalid}
  end

  defp is_valid({:error, _}), do: false
  defp is_valid(_), do: true
end
