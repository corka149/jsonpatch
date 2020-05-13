defmodule Jsonpatch.Operation.Remove do
  @behaviour Jsonpatch.Operation

  @enforce_keys [:path]
  defstruct [:path]

  @doc """
  Removes the element referenced by the JSON patch path.

  ## Examples

      iex> remove = %Jsonpatch.Operation.Remove{path: "/a/b"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.Remove.apply_op(remove, target)
      %{"a" => %{}, "d" => false}
  """
  @impl true
  def apply_op(%Jsonpatch.Operation.Remove{path: path}, target) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    do_remove(target, fragments)
  end

  # ===== ===== PRIVATE ===== =====

  defp do_remove(target, [fragment | []]) do
    {_, purged_map} = Map.pop(target, fragment)
    purged_map
  end

  defp do_remove(target, [fragment | tail]) do
    Map.update!(target, fragment, &do_remove(&1, tail))
  end
end
