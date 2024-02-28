defmodule Jsonpatch.Operation.Add do
  @moduledoc """
  The add operation is the operation for creating/updating values.
  Values can be inserted in a list using an index or appended using a `-`.

  ## Examples

      iex> add = %Add{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"c" => false}}
      iex> Jsonpatch.Operation.Add.apply(add, target, [])
      {:ok, %{"a" => %{"b" => 1, "c" => false}}}

      iex> add = %Add{path: "/a/1", value: "b"}
      iex> target = %{"a" => ["a", "c"]}
      iex> Jsonpatch.Operation.Add.apply(add, target, [])
      {:ok, %{"a" => ["a", "b", "c"]}}

      iex> add = %Add{path: "/a/-", value: "z"}
      iex> target = %{"a" => ["x", "y"]}
      iex> Jsonpatch.Operation.Add.apply(add, target, [])
      {:ok, %{"a" => ["x", "y", "z"]}}
  """

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Types
  alias Jsonpatch.Utils

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}

  @spec apply(Jsonpatch.t(), target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | Types.error()
  def apply(%Add{path: path, value: value}, target, opts) do
    with {:ok, destination} <- Utils.get_destination(target, path, opts),
         {:ok, updated_destination} <- do_add(destination, value, opts) do
      Utils.update_destination(target, updated_destination, path, opts)
    end
  end

  defp do_add({_destination, :root}, value, _opts) do
    {:ok, value}
  end

  defp do_add({%{} = destination, last_fragment}, value, _opts) do
    {:ok, Map.put(destination, last_fragment, value)}
  end

  defp do_add({destination, last_fragment}, value, _opts) when is_list(destination) do
    index = to_index(last_fragment)
    {:ok, List.insert_at(destination, index, value)}
  end

  defp to_index(:-), do: -1
  defp to_index(index), do: index
end
