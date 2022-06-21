defmodule Jsonpatch.Operation.Remove do
  @moduledoc """
  A JSON patch remove operation is responsible for removing values.

  ## Examples

      iex> remove = %Jsonpatch.Operation.Remove{path: "/a/b"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.apply_op(remove, target)
      %{"a" => %{}, "d" => false}
  """

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.PathUtil

  @enforce_keys [:path]
  defstruct [:path]
  @type t :: %__MODULE__{path: String.t()}

  defimpl Operation do
    @spec apply_op(Remove.t(), list() | map() | Jsonpatch.error(), keyword()) ::
            map()
    def apply_op(_, {:error, _, _} = error, _opts), do: error

    def apply_op(%Remove{path: path}, target, opts) do
      key_type = PathUtil.wanted_key_type(opts)

      # The first element is always "" which is useless.
      [_ | fragments] =
        path
        |> String.split("/")
        |> Enum.map(&PathUtil.unescape/1)
        |> PathUtil.into_key_type(key_type)

      do_remove(target, fragments)
    end

    # ===== ===== PRIVATE ===== =====

    defp get_at(list, index) do
      case Enum.at(list, index) do
        nil -> {:error, :invalid_index, index}
        ele -> {:ok, ele}
      end
    end

    defp remove_in_list(list, val, index, subpath) do
      case do_remove(val, subpath) do
        {:error, _, _} = error -> error
        new_val -> List.replace_at(list, index, new_val)
      end
    end

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
          case get_at(target, index) do
            {:ok, new_val} -> remove_in_list(target, new_val, index, tail)
            {:error, _, _} = error -> error
          end
      end
    end
  end
end
