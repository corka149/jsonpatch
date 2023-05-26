defmodule Jsonpatch.Operation.Test do
  @moduledoc """
  A test operation in a JSON patch prevents the patch application or allows it.

  ## Examples

    iex> test = %Jsonpatch.Operation.Test{path: "/x/y", value: "Bob"}
    iex> target = %{"x" => %{"y" => "Bob"}}
    iex> Jsonpatch.Operation.Test.apply(test, target, [])
    {:ok, %{"x" => %{"y" => "Bob"}}}
  """

  alias Jsonpatch.Operation.Test
  alias Jsonpatch.Types
  alias Jsonpatch.Utils

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}

  @spec apply(Jsonpatch.t(), target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | Types.error()
  def apply(%Test{path: path, value: value}, target, opts) do
    with {:ok, destination} <- Utils.get_destination(target, path, opts),
         {:ok, test_path} = Utils.split_path(path),
         {:ok, true} <- do_test(destination, value, test_path) do
      {:ok, target}
    else
      {:ok, false} ->
        {:error, {:test_failed, "Expected value '#{inspect(value)}' at '#{path}'"}}

      {:error, _} = error ->
        error
    end
  end

  defp do_test({%{} = target, last_fragment}, value, _path) do
    case target do
      %{^last_fragment => ^value} -> {:ok, true}
      %{} -> {:ok, false}
    end
  end

  defp do_test({target, index}, value, path) when is_list(target) do
    case Utils.fetch(target, index) do
      {:ok, fetched_value} ->
        {:ok, fetched_value == value}

      {:error, :invalid_path} ->
        {:error, {:invalid_path, path}}
    end
  end
end
