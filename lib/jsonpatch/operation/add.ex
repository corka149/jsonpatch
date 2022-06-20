defmodule Jsonpatch.Operation.Add do
  @moduledoc """
  The add operation is the operation for adding values to a map or struct.
  Values can be appended to lists by using `-` instead of an index.

  ## Examples

      iex> add = %Add{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"c" => false}}
      iex> Operation.apply_op(add, target)
      %{"a" => %{"b" => 1, "c" => false}}

      iex> add = %Add{path: "/a/-", value: "z"}
      iex> target = %{"a" => ["x", "y"]}
      iex> Operation.apply_op(add, target)
      %{"a" => ["x", "y", "z"]}
  """

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Add
  alias Jsonpatch.PathUtil

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}

  defimpl Operation do
    @spec apply_op(Add.t(), list() | map() | Jsonpatch.error(), keyword()) :: map
    def apply_op(_, {:error, _, _} = error, _opt), do: error

    def apply_op(%Add{path: path, value: value}, target, opts) do
      PathUtil.get_final_destination(target, path, opts)
      |> do_add(target, path, value, opts)
    end

    # ===== ===== PRIVATE ===== =====

    # Error
    defp do_add({:error, _, _} = error, _target, _path, _value, _opts), do: error

    # Map
    defp do_add({%{} = final_destination, last_fragment}, target, path, value, opts) do
      updated_final_destination = Map.put_new(final_destination, last_fragment, value)
      PathUtil.update_final_destination(target, updated_final_destination, path, opts)
    end

    # List
    defp do_add({final_destination, last_fragment}, target, path, value, opts)
         when is_list(final_destination) do
      case parse_index(final_destination, last_fragment) do
        {:error, _, _} = error ->
          error

        index ->
          updated_final_destination =
            if last_fragment == "-" or length(final_destination) == index do
              Enum.concat(final_destination, [value])
            else
              List.update_at(final_destination, index, fn _ -> value end)
            end

          PathUtil.update_final_destination(
            target,
            updated_final_destination,
            path,
            opts
          )
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
end
