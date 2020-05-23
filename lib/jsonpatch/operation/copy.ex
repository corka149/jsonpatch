defmodule Jsonpatch.Operation.Copy do
  @moduledoc """
  Represents the handling of JSON patches with a copy operation.
  """

  @behaviour Jsonpatch.Operation

  @enforce_keys [:from, :path]
  defstruct [:from, :path]
  @type t :: %__MODULE__{from: String.t(), path: String.t()}

  @doc """
  Copy the element referenced by the JSON patch path :from to to the other
  given path.

  ## Examples

      iex> copy = %Jsonpatch.Operation.Copy{from: "/a/b", path: "/a/e"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.Copy.apply_op(copy, target)
      %{"a" => %{"b" => %{"c" => "Bob"}, "e" => %{"c" => "Bob"}}, "d" => false}
  """
  @impl true
  @spec apply_op(Jsonpatch.Operation.Copy.t(), map) :: map
  def apply_op(%Jsonpatch.Operation.Copy{from: from, path: path}, target) do
    # %{"c" => "Bob"}
    copied_value =
      target
      |> Jsonpatch.Operation.get_final_destination!(from)
      |> extract_copy_value()

    # "e"
    copy_path_end = String.split(path, "/") |> List.last()

    # %{"b" => %{"c" => "Bob"}, "e" => %{"c" => "Bob"}}
    updated_value =
      target
      # %{"b" => %{"c" => "Bob"}} is the "copy target"
      |> Jsonpatch.Operation.get_final_destination!(path)
      # Add copied_value to "copy target"
      |> do_add(copied_value, copy_path_end)

    Jsonpatch.Operation.update_final_destination!(target, updated_value, path)
  end

  # ===== ===== PRIVATE ===== =====

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
end
