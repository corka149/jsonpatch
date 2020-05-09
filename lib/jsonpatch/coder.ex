defmodule Jsonpatch.Coder do
  @moduledoc """
  Cares of de- and encoding of json patches.
  """

  @doc """
  Encodes a patch into a JSON string.

  ## Examples

      iex> Jsonpatch.Coder.encode(%Jsonpatch.Operation.Add{path: "/age", value: 1})
      {:ok, "{'op': 'add','value': '1','path': '/age'}"}
  """
  @spec encode(list(Jsonpatch.operation()) | Jsonpatch.operation()) ::
          {:ok, iodata} | {:ok, String.t()} | {:error, {:invalid, any}} | {:error, bitstring()}
  def encode(patch)

  def encode(patch_operations) when is_list(patch_operations) do
    Enum.map(patch_operations, &prepare/1) |> Poison.encode()
  end

  def encode(%{} = patch_operation) do
    prepare(patch_operation)
    |> Poison.encode()
  end

  def encode(_) do
    {:error, "Parameters could not be encoded"}
  end

  # ===== ===== PRIVATE ===== =====

  defp prepare(%Jsonpatch.Operation.Add{} = operation) do
    Map.put(operation, "op", "add")
  end

  defp prepare(%Jsonpatch.Operation.Remove{} = operation) do
    Map.put(operation, "op", "remove")
  end

  defp prepare(%Jsonpatch.Operation.Replace{} = operation) do
    Map.put(operation, "op", "replace")
  end
end
