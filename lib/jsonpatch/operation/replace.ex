defmodule Jsonpatch.Operation.Replace do
  @moduledoc """
  The replace module helps replacing values in maps and structs by paths.

  ## Examples

      iex> add = %Jsonpatch.Operation.Replace{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"b" => 2}}
      iex> Jsonpatch.Operation.apply_op(add, target)
      %{"a" => %{"b" => 1}}
  """

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}

  defimpl Jsonpatch.Operation do
    @spec apply_op(Jsonpatch.Operation.Replace.t(), map | Jsonpatch.error(), keyword()) :: map
    def apply_op(_, {:error, _, _} = error, _opts), do: error

    def apply_op(%Jsonpatch.Operation.Replace{path: path, value: value}, %{} = target, opts) do
      {final_destination, last_fragment} =
        Jsonpatch.PathUtil.get_final_destination(target, path, opts)

      case do_update(final_destination, last_fragment, value) do
        {:error, _, _} = error ->
          error

        updated_final_destination ->
          Jsonpatch.PathUtil.update_final_destination(target, updated_final_destination, path)
      end
    end

    # ===== ===== PRIVATE ===== =====

    defp do_update(%{} = final_destination, last_fragment, value) do
      case final_destination do
        %{^last_fragment => _} -> %{final_destination | last_fragment => value}
        _ -> {:error, :invalid_path, last_fragment}
      end
    end

    defp do_update(final_destination, last_fragment, value) when is_list(final_destination) do
      case Integer.parse(last_fragment) do
        :error ->
          {:error, :invalid_index, last_fragment}

        {index, _} ->
          case List.pop_at(final_destination, index) do
            {nil, _} -> {:error, :invalid_index, last_fragment}
            _ -> List.replace_at(final_destination, index, value)
          end
      end
    end
  end
end
