defmodule Jsonpatch.Operation.Remove do
  @moduledoc """
  A JSON patch remove operation is responsible for removing values.
  """

  @behaviour Jsonpatch.Operation

  @enforce_keys [:path]
  defstruct [:path]
  @type t :: %__MODULE__{path: String.t()}

  @doc """
  Removes the element referenced by the JSON patch path.

  ## Examples

      iex> remove = %Jsonpatch.Operation.Remove{path: "/a/b"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.Remove.apply_op(remove, target)
      %{"a" => %{}, "d" => false}
  """
  @impl true
  @spec apply_op(Jsonpatch.Operation.Remove.t(), map) :: map
  def apply_op(%Jsonpatch.Operation.Remove{path: path}, target) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    do_remove(target, fragments)
  end

  # ===== ===== PRIVATE ===== =====

  defp do_remove(%{} = target, [fragment | []]) do
    {_, purged_map} = Map.pop(target, fragment)
    purged_map
  end

  defp do_remove(target, [fragment | []]) when is_list(target) do
    {index, _} = Integer.parse(fragment)
    {_, purged_list} = List.pop_at(target, index)
    purged_list
  end

  defp do_remove(%{} = target, [fragment | tail]) do
    Map.update!(target, fragment, &do_remove(&1, tail))
  end

  defp do_remove(target, [fragment | tail]) when is_list(target) do
    {index, _} = Integer.parse(fragment)

    List.update_at(target, index, &do_remove(&1, tail))
  end
end
