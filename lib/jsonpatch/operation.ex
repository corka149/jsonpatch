defprotocol Jsonpatch.Operation do
  @moduledoc """
  The Operation module is responsible for applying patches. For examples see in the
  available implementation from this library for this protocol:

  - Jsonpatch.Operation.Add
  - Jsonpatch.Operation.Copy
  - Jsonpatch.Operation.Move
  - Jsonpatch.Operation.Remove
  - Jsonpatch.Operation.Replace
  - Jsonpatch.Operation.Test

  """

  @doc """
  Executes the given patch to map/struct.
  """
  @spec apply_op(Jsonpatch.t(), map() | Jsonpatch.error()) :: map() | Jsonpatch.error()
  def apply_op(patch, target)
end
