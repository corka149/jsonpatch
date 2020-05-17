defmodule Jsonpatch.Coder do
  @moduledoc """
  Cares of de- and encoding of json patches.
  """

  @doc ~S"""
  Encodes a patch into a JSON string.

  ## Examples

      iex> Jsonpatch.Coder.encode(%Jsonpatch.Operation.Add{path: "/age", value: 1})
      {:ok, "{\"op\": \"add\",\"value\": \"1\",\"path\": \"/age\"}"}
  """
  @spec encode(list(Jsonpatch.Operation.t()) | Jsonpatch.Operation.t()) ::
          {:ok, iodata} | {:ok, String.t()} | {:error, {:invalid, any}} | {:error, :invalid}
  def encode(patch)

  def encode(patch_operations) when is_list(patch_operations) do
    Enum.map(patch_operations, &prepare/1)
    |> Enum.filter(&is_valid/1)
    |> Poison.encode()
  end

  def encode(%{} = patch_operation) do
    case prepare(patch_operation) do
      {:error, _} = error -> error
      patch -> Poison.encode(patch)
    end
  end

  def encode(_) do
    {:error, :invalid}
  end

  @doc ~S"""
  Decodes a JSON patch string into patch structs.

  ## Examples

      iex> Jsonpatch.Coder.decode("{\"op\": \"add\",\"value\": \"1\",\"path\": \"/age\"}")
      {:ok, %Jsonpatch.Operation.Add{path: "/age", value: 1}}
  """
  @spec decode(iodata()) ::
          {:error, :invalid} | Jsonpatch.Operation.t() | list(Jsonpatch.Operation.t())
  def decode(json_patch_str) do
    Poison.decode(json_patch_str)
    |> convert_to()
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

  defp prepare(_) do
    {:error, :invalid}
  end

  defp convert_to({:ok, json_patch}) when is_list(json_patch) do
    Enum.map(json_patch, fn patch_part -> convert_to({:ok, patch_part}) end)
  end

  defp convert_to({:ok, %{"op" => "add", "path" => path, "value" => value}}) do
    %Jsonpatch.Operation.Add{path: path, value: value}
  end

  defp convert_to({:ok, %{"op" => "remove", "path" => path}}) do
    %Jsonpatch.Operation.Remove{path: path}
  end

  defp convert_to({:ok, %{"op" => "replace", "path" => path, "value" => value}}) do
    %Jsonpatch.Operation.Replace{path: path, value: value}
  end

  defp convert_to({:ok, %{"op" => "copy", "from" => from, "path" => path}}) do
    %Jsonpatch.Operation.Copy{from: from, path: path}
  end

  defp convert_to({:ok, %{"op" => "move", "from" => from, "path" => path}}) do
    %Jsonpatch.Operation.Move{from: from, path: path}
  end

  defp convert_to(_) do
    {:error, :invalid}
  end

  defp is_valid({:error, _}), do: false
  defp is_valid(_), do: true
end
