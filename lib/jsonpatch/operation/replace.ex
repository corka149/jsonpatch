defmodule Jsonpatch.Operation.Replace do
  @moduledoc """
  The replace module helps replacing values in maps and structs by paths.
  """

  @behaviour Jsonpatch.Operation

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}

  @doc """
  Applies an replace operation to a struct/map.

  ## Examples

      iex> add = %Jsonpatch.Operation.Replace{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"b" => 2}}
      iex> Jsonpatch.Operation.Replace.apply_op(add, target)
      %{"a" => %{"b" => 1}}
  """
  @impl true
  @spec apply_op(Jsonpatch.Operation.Replace.t(), map) :: map
  def apply_op(%Jsonpatch.Operation.Replace{path: path, value: value}, %{} = target) do
    {final_destination, last_fragment} = Jsonpatch.Operation.get_final_destination(target, path)
    updated_final_destination = do_update(final_destination, last_fragment, value)
    Jsonpatch.Operation.update_final_destination!(target, updated_final_destination, path)
  end

  # ===== ===== PRIVATE ===== =====

  defp do_update(%{} = final_destination, last_fragment, value) do
    if Map.has_key?(final_destination, last_fragment) do
      Map.replace!(final_destination, last_fragment, value)
    else
      final_destination
    end
  end

  defp do_update(final_destination, last_fragment, value) when is_list(final_destination) do
    {index, _} = Integer.parse(last_fragment)

    List.replace_at(final_destination, index, value)
  end
end
