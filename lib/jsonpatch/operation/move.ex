defmodule Jsonpatch.Operation.Move do
  @moduledoc """
  Move operations change the position of values in map or struct.

  ## Examples

      iex> move = %Jsonpatch.Operation.Move{from: "/a/b", path: "/a/e"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.Move.apply(move, target, [])
      {:ok, %{"a" => %{"e" => %{"c" => "Bob"}}, "d" => false}}
  """

  alias Jsonpatch.Operation.{Copy, Move, Remove}
  alias Jsonpatch.Types

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}

  @spec apply(Jsonpatch.t(), target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | Types.error()
  def apply(%Move{from: from, path: path}, target, opts) do
    copy_patch = %Copy{from: from, path: path}
    remove_patch = %Remove{path: from}

    with {:ok, res} <- Copy.apply(copy_patch, target, opts),
         {:ok, res} <- Remove.apply(remove_patch, res, opts) do
      {:ok, res}
    end
  end
end
