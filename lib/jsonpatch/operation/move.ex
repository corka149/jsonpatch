defmodule Jsonpatch.PathUtil.Move do
  @moduledoc """
  Move operations change the position of values in map or struct.
  """

  @behaviour Jsonpatch.PathUtil

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}

  alias Jsonpatch.PathUtil.Copy
  alias Jsonpatch.PathUtil.Remove

  @doc """
  Move the element referenced by the JSON patch path :from to to the other
  given path.

  ## Examples

      iex> move = %Jsonpatch.PathUtil.Move{from: "/a/b", path: "/a/e"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.PathUtil.Move.apply_op(move, target)
      %{"a" => %{"e" => %{"c" => "Bob"}}, "d" => false}
  """
  @impl true
  @spec apply_op(Jsonpatch.PathUtil.Move.t(), map) :: map | :error
  def apply_op(%Jsonpatch.PathUtil.Move{from: from, path: path}, target) do
    copy_patch = %Copy{from: from, path: path}

    case Copy.apply_op(copy_patch, target) do
      :error -> :error
      updated_target -> Remove.apply_op(%Remove{path: from}, updated_target)
    end
  end
end
