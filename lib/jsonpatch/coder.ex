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
    Jsonpatch.Mapper.to_map(patch_operations)
    |> Poison.encode()
  end

  def encode(%{} = patch_operation) do
    case Jsonpatch.Mapper.to_map(patch_operation) do
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
    case Poison.decode(json_patch_str) do
      {:ok, parsed} -> Jsonpatch.Mapper.from_map(parsed)
      # _ -> {:error, :invalid} # dialyzer says, it could never match.
    end
  end

end
