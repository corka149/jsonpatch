defmodule Jsonpatch.Operation.Move do
  @moduledoc """
  Move operations change the position of values in map or struct.
  """

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}
end

defimpl Jsonpatch.Operation, for: Jsonpatch.Operation.Move do
  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Copy
  alias Jsonpatch.Operation.Remove

  @doc """
  Move the element referenced by the JSON patch path :from to to the other
  given path.

  ## Examples

      iex> move = %Jsonpatch.Operation.Move{from: "/a/b", path: "/a/e"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.apply_op(move, target)
      %{"a" => %{"e" => %{"c" => "Bob"}}, "d" => false}
  """
  @spec apply_op(Jsonpatch.Operation.Move.t(), map | :error) :: map | :error
  def apply_op(%Jsonpatch.Operation.Move{from: from, path: path}, target) do
    copy_patch = %Copy{from: from, path: path}

    case Operation.apply_op(copy_patch, target) do
      :error -> :error
      updated_target -> Operation.apply_op(%Remove{path: from}, updated_target)
    end
  end

  def apply_op(_, :error), do: :error
end
