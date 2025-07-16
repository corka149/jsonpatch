defmodule Jsonpatch.Operation.Move do
  @moduledoc """
  Move operations change the position of values in map or struct.

  ## Examples

      iex> move = %Jsonpatch.Operation.Move{from: "/a/b", path: "/a/e"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.Move.apply(move, target, [])
      {:ok, %{"a" => %{"e" => %{"c" => "Bob"}}, "d" => false}}
  """

  alias Jsonpatch.Operation.{Add, Move, Remove}
  alias Jsonpatch.Types
  alias Jsonpatch.Utils

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}

  @spec apply(Jsonpatch.t(), target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | Types.error()
  def apply(%Move{from: from, path: path}, target, opts) do
    if from != path do
      do_move(from, path, target, opts)
    else
      {:ok, target}
    end
  end

  defp do_move(from, path, target, opts) do
    remove_patch = %Remove{path: from}

    with {:ok, destination} <- Utils.get_destination(target, from, opts),
         {:ok, from_fragments} = Utils.split_path(from),
         {:ok, copy_value} <- extract_copy_value(destination, from_fragments),
         {:ok, res} <- Remove.apply(remove_patch, target, opts),
         {:ok, res} <- Add.apply(%Add{value: copy_value, path: path}, res, opts) do
      {:ok, res}
    end
  end

  defp extract_copy_value({%{} = destination, fragment}, from_path) do
    case destination do
      %{^fragment => val} -> {:ok, val}
      _ -> {:error, {:invalid_path, from_path}}
    end
  end

  defp extract_copy_value({destination, index}, from_path) when is_list(destination) do
    case Utils.fetch(destination, index) do
      {:ok, _} = ok -> ok
      {:error, :invalid_path} -> {:error, {:invalid_path, from_path}}
    end
  end
end
