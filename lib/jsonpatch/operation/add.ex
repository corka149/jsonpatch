defmodule Jsonpatch.Operation.Add do
  @moduledoc """
  The add operation is the operation for adding (as you might guess) values to a map or struct.

  ## Examples

      iex> add = %Jsonpatch.Operation.Add{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"c" => false}}
      iex> Jsonpatch.Operation.apply_op(add, target)
      %{"a" => %{"b" => 1, "c" => false}}
  """

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}
end

defimpl Jsonpatch.Operation, for: Jsonpatch.Operation.Add do

  @spec apply_op(Jsonpatch.Operation.Add.t(), map | :error) :: map
  def apply_op(%Jsonpatch.Operation.Add{path: path, value: value}, %{} = target) do
    case Jsonpatch.PathUtil.get_final_destination(target, path) do
      {:error, _} ->
        target

      {final_destination, last_fragment} ->
        updated_final_destination = Map.put_new(final_destination, last_fragment, value)
        Jsonpatch.PathUtil.update_final_destination(target, updated_final_destination, path)
    end
  end

  def apply_op(_, :error), do: :error
end
