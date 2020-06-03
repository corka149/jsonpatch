defmodule Jsonpatch.Operation.Remove do
  @moduledoc """
  A JSON patch remove operation is responsible for removing values.

  ## Examples

      iex> remove = %Jsonpatch.Operation.Remove{path: "/a/b"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.apply_op(remove, target)
      %{"a" => %{}, "d" => false}
  """

  @enforce_keys [:path]
  defstruct [:path]
  @type t :: %__MODULE__{path: String.t()}
end

defimpl Jsonpatch.Operation, for: Jsonpatch.Operation.Remove do
  @spec apply_op(Jsonpatch.Operation.Remove.t(), map | Jsonpatch.error()) ::
          map | Jsonpatch.error()
  def apply_op(%Jsonpatch.Operation.Remove{path: path}, target) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    do_remove(target, fragments)
  end

  def apply_op(_, {:error, _, _} = error), do: error

  # ===== ===== PRIVATE ===== =====

  defp do_remove(%{} = target, [fragment | []]) do
    case Map.pop(target, fragment) do
      {nil, _} -> {:error, :invalid_path, fragment}
      {_, purged_map} -> purged_map
    end
  end

  defp do_remove(target, [fragment | []]) when is_list(target) do
    case Integer.parse(fragment) do
      :error ->
        {:error, :invalid_index, fragment}

      {index, _} ->
        case List.pop_at(target, index) do
          {nil, _} -> {:error, :invalid_index, fragment}
          {_, purged_list} -> purged_list
        end
    end
  end

  defp do_remove(%{} = target, [fragment | tail]) do
    case Map.get(target, fragment) do
      nil ->
        {:error, :invalid_path, fragment}

      val ->
        case do_remove(val, tail) do
          {:error, _, _} = error -> error
          new_val -> %{target | fragment => new_val}
        end
    end
  end

  defp do_remove(target, [fragment | tail]) when is_list(target) do
    case Integer.parse(fragment) do
      :error ->
        {:error, :invalid_index, fragment}

      {index, _} ->
        update_list = List.update_at(target, index, &do_remove(&1, tail))

        case List.pop_at(target, index) do
          {nil, _} -> {:error, :invalid_index, fragment}
          {{:error, _, _} = error, _} -> error
          _ -> update_list
        end
    end
  end

  defp do_remove({:error, _, _} = error, _) do
    error
  end
end
