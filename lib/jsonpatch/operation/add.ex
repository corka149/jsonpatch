defmodule Jsonpatch.Operation.Add do
  @behaviour Jsonpatch.Operation

  @enforce_keys [:path, :value]
  defstruct [:path, :value]

  @doc """
  Applies an add operation a struct/map.

  ## Examples

      iex> add = %Jsonpatch.Operation.Add{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"c" => false}}
      iex> Jsonpatch.Operation.Add.apply_op(add, target)
      %{"a" => %{"b" => 1, "c" => false}}
  """
  @impl true
  @spec apply_op(Jsonpatch.Operation.Add.t(), map) :: map
  def apply_op(%Jsonpatch.Operation.Add{path: path, value: value}, %{} = target) do
    {final_destination, last_fragment} = Jsonpatch.Operation.get_final_destination!(target, path)
    updated_final_destination = Map.put_new(final_destination, last_fragment, value)
    Jsonpatch.Operation.update_final_destination!(target, updated_final_destination, path)
  end
end
