defprotocol Jsonpatch.Operation do
  @moduledoc """
  The Operation module is responsible for applying patches.
  """

  @doc """
  Executes the given patch to map/struct.
  """
  @spec apply_op(Jsonpatch.t(), map()) :: map() | :ok | :error
  def apply_op(patch, target)
end
