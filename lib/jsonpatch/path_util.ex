defmodule Jsonpatch.PathUtil do
  @moduledoc false

  # ===== Internal documentation =====
  # Helper module for handling JSON paths.

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace
  alias Jsonpatch.Operation.Test

  @doc """
  Uses a JSON patch path to get the last map that this path references.

  ## Examples

      iex> path = "/a/b/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
      iex> Jsonpatch.PathUtil.get_final_destination(target, path)
      {%{"d" => 1}, "d"}

      iex> # Invalid path
      iex> path = "/a/e/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
      iex> Jsonpatch.PathUtil.get_final_destination(target, path)
      {:error, :invalid_path, "e"}

      iex> path = "/a/b/1/d"
      iex> target = %{"a" => %{"b" => [true, %{"d" => 1}]}}
      iex> Jsonpatch.PathUtil.get_final_destination(target, path)
      {%{"d" => 1}, "d"}

      iex> # Invalid path
      iex> path = "/a/b/42/d"
      iex> target = %{"a" => %{"b" => [true, %{"d" => 1}]}}
      iex> Jsonpatch.PathUtil.get_final_destination(target, path)
      {:error, :invalid_index, "42"}
  """
  @spec get_final_destination(map, binary) ::
          {map, binary} | {list, binary} | Jsonpatch.error()
  def get_final_destination(target, path) when is_bitstring(path) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    find_final_destination(target, fragments)
  end

  @doc """
  Updatest a map reference by a given JSON patch path with the new final destination.

  ## Examples

      iex> path = "/a/b/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
      iex> Jsonpatch.PathUtil.update_final_destination(target, %{"e" => 1}, path)
      %{"a" => %{"b" => %{"c" => %{"e" => 1}}}}
  """
  @spec update_final_destination(map, map, binary) :: map | Jsonpatch.error()
  def update_final_destination(target, new_destination, path) do
    # The first element is always "" which is useless.
    [_ | fragments] = String.split(path, "/")
    do_update_final_destination(target, new_destination, fragments)
  end

  @doc """
  Determines the sort value for the operation of a patch. This value
  assure in which order patches are applied. (Example: shall remove
  patches be applied before add patches?)
  """
  @spec operation_sort_value?(Jsonpatch.t()) :: integer()
  def operation_sort_value?(patch)

  def operation_sort_value?(%Test{}), do: 600
  def operation_sort_value?(%Add{}), do: 500
  def operation_sort_value?(%Replace{}), do: 400
  def operation_sort_value?(%Remove{}), do: 300
  def operation_sort_value?(_), do: 0

  # ===== ===== PRIVATE ===== =====

  defp find_final_destination({:error, _, _} = error, _) do
    error
  end

  defp find_final_destination(%{} = target, [fragment | []]) do
    {target, fragment}
  end

  defp find_final_destination(target, [fragment | []]) when is_list(target) do
    {target, fragment}
  end

  defp find_final_destination(%{} = target, [fragment | tail]) do
    case Map.get(target, fragment) do
      nil -> {:error, :invalid_path, fragment}
      val -> find_final_destination(val, tail)
    end
  end

  defp find_final_destination(target, [fragment | tail]) when is_list(target) do
    {index, _} = Integer.parse(fragment)

    case Enum.with_index(target) |> Enum.find(fn {_val, i} -> i == index end) do
      nil -> {:error, :invalid_index, fragment}
      {val, _} -> find_final_destination(val, tail)
    end
  end

  # " [final_dest | [_last_ele |[]]] " means: We want to stop, when there are only two elements left.
  defp do_update_final_destination(%{} = target, new_final_dest, [final_dest | [_last_ele | []]]) do
    Map.replace!(target, final_dest, new_final_dest)
  end

  defp do_update_final_destination(target, new_final_dest, [final_dest | [_last_ele | []]])
       when is_list(target) do
    {index, _} = Integer.parse(final_dest)

    List.replace_at(target, index, new_final_dest)
  end

  defp do_update_final_destination(_target, new_final_dest, [_fragment | []]) do
    new_final_dest
  end

  defp do_update_final_destination(%{} = target, new_final_dest, [fragment | tail]) do
    case Map.get(target, fragment) do
      nil ->
        {:error, :invalid_path, fragment}

      val ->
        case do_update_final_destination(val, new_final_dest, tail) do
          {:error, _, _} = error -> error
          updated_val -> %{target | fragment => updated_val}
        end
    end
  end

  defp do_update_final_destination(target, new_final_dest, [fragment | tail])
       when is_list(target) do
    {index, _} = Integer.parse(fragment)

    List.update_at(target, index, &do_update_final_destination(&1, new_final_dest, tail))
  end
end
