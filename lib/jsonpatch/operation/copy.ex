defmodule Jsonpatch.Operation.Copy do
  @moduledoc """
  Represents the handling of JSON patches with a copy operation.

  ## Examples

    iex> copy = %Jsonpatch.Operation.Copy{from: "/a/b", path: "/a/e"}
    iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
    iex> Jsonpatch.Operation.Copy.apply(copy, target, [])
    {:ok, %{"a" => %{"b" => %{"c" => "Bob"}, "e" => %{"c" => "Bob"}}, "d" => false}}
  """

  alias Jsonpatch.Types
  alias Jsonpatch.Operation.{Add, Copy}
  alias Jsonpatch.Utils

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}

  @spec apply(Jsonpatch.t(), target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | Types.error()
  def apply(%Copy{from: from, path: path}, target, opts) do
    with {:ok, destination} <- Utils.get_destination(target, from, opts),
         {:ok, from_fragments} = Utils.split_path(from),
         {:ok, copy_value} <- extract_copy_value(destination, from_fragments) do
      Add.apply(%Add{value: copy_value, path: path}, target, opts)
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
