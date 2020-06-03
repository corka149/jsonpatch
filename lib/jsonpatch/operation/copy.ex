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
end

defimpl Jsonpatch.Operation, for: Jsonpatch.Operation.Copy do
  @spec apply_op(Jsonpatch.Operation.Copy.t(), map() | Jsonpatch.error()) :: map()
  def apply_op(%Jsonpatch.Operation.Copy{from: from, path: path}, target) do
    # %{"c" => "Bob"}

    updated_val =
      target
      |> Jsonpatch.PathUtil.get_final_destination(from)
      |> extract_copy_value()
      |> do_copy(target, path)

    case updated_val do
      {:error, _, _} = error -> error
      updated_val -> updated_val
    end
  end

  def apply_op(_, {:error, _, _} = error), do: error

  # ===== ===== PRIVATE ===== =====

  defp do_copy(nil, target, _path) do
    target
  end

  defp do_copy({:error, _, _} = error, _target, _path) do
    error
  end

  defp do_copy(copied_value, target, path) do
    # copied_value = %{"c" => "Bob"}

    # "e"
    copy_path_end = String.split(path, "/") |> List.last()

    # %{"b" => %{"c" => "Bob"}, "e" => %{"c" => "Bob"}}
    updated_value =
      target
      # %{"b" => %{"c" => "Bob"}} is the "copy target"
      |> Jsonpatch.PathUtil.get_final_destination(path)
      # Add copied_value to "copy target"
      |> do_add(copied_value, copy_path_end)

    case updated_value do
      {:error, _, _} = error -> error
      updated_value -> Jsonpatch.PathUtil.update_final_destination(target, updated_value, path)
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
        result =
          final_destination
          |> Enum.with_index()
          |> Enum.find(fn {_, other_index} -> index == other_index end)

        case result do
          nil -> {:error, :invalid_index, fragment}
          {val, _} -> val
        end
    end
  end

  defp extract_copy_value({:error, _, _} = error) do
    error
  end

  defp do_add({%{} = copy_target, _last_fragment}, copied_value, copy_path_end) do
    Map.put(copy_target, copy_path_end, copied_value)
  end

  defp do_add({copy_target, _last_fragment}, copied_value, copy_path_end)
       when is_list(copy_target) do
    case Integer.parse(copy_path_end) do
      :error ->
        {:error, :invalid_index, copy_target}

      {index, _} ->
        List.insert_at(copy_target, index, copied_value)
    end
  end

  defp do_add({:error, _, _} = error, _, _) do
    error
  end
end
