defmodule Jsonpatch.Operation.Remove do
  @moduledoc """
  A JSON patch remove operation is responsible for removing values.

  ## Examples

      iex> remove = %Jsonpatch.Operation.Remove{path: "/a/b"}
      iex> target = %{"a" => %{"b" => %{"c" => "Bob"}}, "d" => false}
      iex> Jsonpatch.Operation.Remove.apply(remove, target, [])
      {:ok, %{"a" => %{}, "d" => false}}

      iex> remove = %Jsonpatch.Operation.Remove{path: "/a/b"}
      iex> target = %{"a" => %{"b" => nil}, "d" => false}
      iex> Jsonpatch.Operation.Remove.apply(remove, target, [])
      {:ok, %{"a" => %{}, "d" => false}}
  """

  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Types
  alias Jsonpatch.Utils

  @enforce_keys [:path]
  defstruct [:path]
  @type t :: %__MODULE__{path: String.t()}

  @spec apply(Jsonpatch.t(), target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | Types.error()
  def apply(%Remove{path: path}, target, opts) do
    with {:ok, fragments} <- Utils.split_path(path) do
      do_remove(target, [], fragments, opts)
    end
  end

  defp do_remove(%{} = target, path, [fragment], opts) do
    with {:ok, fragment} <- Utils.cast_fragment(fragment, path, target, opts),
         %{^fragment => _} <- target do
      {:ok, Map.delete(target, fragment)}
    else
      %{} ->
        {:error, {:invalid_path, path ++ [fragment]}}

      # coveralls-ignore-start
      {:error, _} = error ->
        error
        # coveralls-ignore-stop
    end
  end

  defp do_remove(%{} = target, path, [fragment | tail], opts) do
    with {:ok, fragment} <- Utils.cast_fragment(fragment, path, target, opts),
         %{^fragment => val} <- target,
         {:ok, new_val} <- do_remove(val, path ++ [fragment], tail, opts) do
      {:ok, %{target | fragment => new_val}}
    else
      %{} -> {:error, {:invalid_path, path ++ [fragment]}}
      {:error, _} = error -> error
    end
  end

  defp do_remove(target, path, [fragment | tail], opts) when is_list(target) do
    case Utils.cast_fragment(fragment, path, target, opts) do
      {:ok, :-} ->
        {:error, {:invalid_path, path ++ [fragment]}}

      {:ok, index} ->
        if tail == [] do
          {:ok, List.delete_at(target, index)}
        else
          Utils.update_at(target, index, path, &do_remove(&1, path ++ [fragment], tail, opts))
        end

      {:error, _} = error ->
        error
    end
  end

  defp do_remove(_target, path, [fragment | _], _opts) do
    {:error, {:invalid_path, path ++ [fragment]}}
  end
end
