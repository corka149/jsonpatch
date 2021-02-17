defmodule Jsonpatch.Operation.Add do
  @moduledoc """
  The add operation is the operation for adding (as you might guess) values to a map or struct.
  Values can be appended to lists by using `-` instead of an index.

  ## Examples

      iex> add = %Jsonpatch.Operation.Add{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"c" => false}}
      iex> Jsonpatch.Operation.apply_op(add, target)
      %{"a" => %{"b" => 1, "c" => false}}

      iex> add = %Jsonpatch.Operation.Add{path: "/a/-", value: "z"}
      iex> target = %{"a" => ["x", "y"]}
      iex> Jsonpatch.Operation.apply_op(add, target)
      %{"a" => ["x", "y", "z"]}
  """

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}
end

defimpl Jsonpatch.Operation, for: Jsonpatch.Operation.Add do
  @spec apply_op(Jsonpatch.Operation.Add.t(), map | Jsonpatch.error()) :: map
  def apply_op(_, {:error, _, _} = error), do: error

  def apply_op(%Jsonpatch.Operation.Add{path: path, value: value}, %{} = target) do
    Jsonpatch.PathUtil.get_final_destination(target, path)
    |> do_add(target, path, value)
  end

  # ===== ===== PRIVATE ===== =====

  # Error
  defp do_add({:error, _, _} = error, _target, _path, _value), do: error

  # Map
  defp do_add({final_destination, last_fragment}, target, path, value)
       when is_map(final_destination) do
    updated_final_destination = Map.put_new(final_destination, last_fragment, value)
    Jsonpatch.PathUtil.update_final_destination(target, updated_final_destination, path)
  end

  # List
  defp do_add({final_destination, last_fragment}, target, path, value)
       when is_list(final_destination) do
    case parse_index(final_destination, last_fragment) do
      {:error, _, _} = error ->
        error

      index ->
        updated_final_destination =
          if last_fragment == "-" do
            Enum.concat(final_destination, [value])
          else
            List.update_at(final_destination, index, fn _ -> value end)
          end

        Jsonpatch.PathUtil.update_final_destination(target, updated_final_destination, path)
    end
  end

  defp parse_index(list, unparsed) do
    if unparsed == "-" do
      length(list)
    else
      case Integer.parse(unparsed) do
        :error -> {:error, :invalid_index, unparsed}
        {index, _} -> index
      end
    end
  end
end
