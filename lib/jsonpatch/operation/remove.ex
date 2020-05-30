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
  @spec apply_op(Jsonpatch.Operation.Remove.t(), map) :: map | :error
  def apply_op(%Jsonpatch.Operation.Remove{path: path}, target) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    do_remove(target, fragments)
  end

  # ===== ===== PRIVATE ===== =====

  defp do_remove(%{} = target, [fragment | []]) do
    case Map.pop(target, fragment) do
      {nil, _} -> :error
      {_, purged_map} -> purged_map
    end
  end

  defp do_remove(target, [fragment | []]) when is_list(target) do
    case Integer.parse(fragment) do
      :error ->
        :error

      {index, _} ->
        case List.pop_at(target, index) do
          {nil, _} -> :error
          {_, purged_list} -> purged_list
        end
    end
  end

  defp do_remove(%{} = target, [fragment | tail]) do
    case Map.get(target, fragment) do
      nil ->
        :error

      val ->
        case do_remove(val, tail) do
          :error -> :error
          new_val -> %{target | fragment => new_val}
        end
    end
  end

  defp do_remove(target, [fragment | tail]) when is_list(target) do
    case Integer.parse(fragment) do
      :error ->
        :error

      {index, _} ->
        update_list = List.update_at(target, index, &do_remove(&1, tail))

        case List.pop_at(target, index) do
          {nil, _} -> :error
          {:error, _} -> :error
          _ -> update_list
        end
    end
  end
end
