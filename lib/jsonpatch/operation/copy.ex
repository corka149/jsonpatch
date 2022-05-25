defmodule Jsonpatch.Operation.Copy do
  @moduledoc """
  Represents the handling of JSON patches with a copy operation.

  ## Examples

      iex> copy = %Jsonpatch.Operation.Copy{from: "/a/b", path: "/a/e"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.apply_op(copy, target)
      %{"a" => %{"b" => %{"c" => "Bob"}, "e" => %{"c" => "Bob"}}, "d" => false}
  """

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}

  defimpl Jsonpatch.Operation do
    @spec apply_op(Jsonpatch.Operation.Copy.t(), map() | Jsonpatch.error(), keyword()) :: map()
    def apply_op(_, {:error, _, _} = error, _opts), do: error

    def apply_op(%Jsonpatch.Operation.Copy{from: from, path: path}, target, opts) do
      # %{"c" => "Bob"}

      updated_val =
        target
        |> Jsonpatch.PathUtil.get_final_destination(from, opts)
        |> extract_copy_value()
        |> do_copy(target, path, opts)

      case updated_val do
        {:error, _, _} = error -> error
        updated_val -> updated_val
      end
    end

    # ===== ===== PRIVATE ===== =====

    defp do_copy({:error, _, _} = error, _target, _path, _opts) do
      error
    end

    defp do_copy(copied_value, target, path, opts) do
      # copied_value = %{"c" => "Bob"}

      # "e"
      copy_path_end = String.split(path, "/") |> List.last()

      # %{"b" => %{"c" => "Bob"}, "e" => %{"c" => "Bob"}}
      updated_value =
        target
        # %{"b" => %{"c" => "Bob"}} is the "copy target"
        |> Jsonpatch.PathUtil.get_final_destination(path, opts)
        # Add copied_value to "copy target"
        |> do_add(copied_value, copy_path_end)

      case updated_value do
        {:error, _, _} = error ->
          error

        updated_value ->
          Jsonpatch.PathUtil.update_final_destination(target, updated_value, path, opts)
      end
    end

    defp extract_copy_value({%{} = final_destination, fragment}) do
      Map.get(final_destination, fragment, {:error, :invalid_path, fragment})
    end

    defp extract_copy_value({final_destination, fragment}) when is_list(final_destination) do
      case Integer.parse(fragment) do
        :error ->
          {:error, :invalid_index, fragment}

        {index, _} ->
          case Enum.fetch(final_destination, index) do
            :error -> {:error, :invalid_index, fragment}
            {:ok, val} -> val
          end
      end
    end

    defp do_add({%{} = copy_target, _last_fragment}, copied_value, copy_path_end) do
      Map.put(copy_target, copy_path_end, copied_value)
    end

    defp do_add({copy_target, _last_fragment}, copied_value, copy_path_end)
         when is_list(copy_target) do
      if copy_path_end == "-" do
        List.insert_at(copy_target, length(copy_target), copied_value)
      else
        case Integer.parse(copy_path_end) do
          :error ->
            {:error, :invalid_index, copy_path_end}

          {index, _} ->
            if index < length(copy_target) do
              List.update_at(copy_target, index, fn _old -> copied_value end)
            else
              {:error, :invalid_index, copy_path_end}
            end
        end
      end
    end

    defp do_add({:error, _, _} = error, _, _) do
      error
    end
  end
end
