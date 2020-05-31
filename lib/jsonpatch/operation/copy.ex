defmodule Jsonpatch.Operation.Copy do
  @moduledoc """
  Represents the handling of JSON patches with a copy operation.
  """

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}
end

defimpl Jsonpatch.Operation, for: Jsonpatch.Operation.Copy do
  @doc """
  Copy the element referenced by the JSON patch path :from to to the other
  given path.

  ## Examples

      iex> copy = %Jsonpatch.Operation.Copy{from: "/a/b", path: "/a/e"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.apply_op(copy, target)
      %{"a" => %{"b" => %{"c" => "Bob"}, "e" => %{"c" => "Bob"}}, "d" => false}
  """
  @spec apply_op(Jsonpatch.Operation.Copy.t(), map() | :error) :: map() | :error
  def apply_op(%Jsonpatch.Operation.Copy{from: from, path: path}, target) do
    # %{"c" => "Bob"}

    updated_val =
      target
      |> Jsonpatch.PathUtil.get_final_destination(from)
      |> extract_copy_value()
      |> do_copy(target, path)

    case updated_val do
      {:error, _} -> :error
      updated_val -> updated_val
    end
  end

  def apply_op(_, :error), do: :error

  # ===== ===== PRIVATE ===== =====

  defp do_copy(nil, target, _path) do
    target
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
      {:error, _} = error -> error
      updated_value -> Jsonpatch.PathUtil.update_final_destination(target, updated_value, path)
    end
  end

  defp extract_copy_value({%{} = final_destination, fragment}) do
    Map.get(final_destination, fragment)
  end

  defp extract_copy_value({final_destination, fragment}) when is_list(final_destination) do
    case Integer.parse(fragment) do
      :error ->
        :error

      {index, _} ->
        {val, _} =
          final_destination
          |> Enum.with_index()
          |> Enum.find(fn {_, other_index} -> index == other_index end)

        val
    end
  end

  defp extract_copy_value({:error, _} = error) do
    error
  end

  defp do_add({%{} = copy_target, _last_fragment}, copied_value, copy_path_end) do
    Map.put(copy_target, copy_path_end, copied_value)
  end

  defp do_add({copy_target, _last_fragment}, copied_value, copy_path_end)
       when is_list(copy_target) do
    case Integer.parse(copy_path_end) do
      :error ->
        :error

      {index, _} ->
        List.insert_at(copy_target, index, copied_value)
    end
  end

  defp do_add({:error, :invalid_path} = error, _, _) do
    error
  end

  defp do_add(_, _, _) do
    {:error, :invalid_parameter}
  end
end
