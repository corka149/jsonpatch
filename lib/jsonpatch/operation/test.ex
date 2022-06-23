defmodule Jsonpatch.Operation.Test do
  @moduledoc """
  A test operation in a JSON patch prevents the patch application or allows it.

  ## Examples

      iex> test = %Jsonpatch.Operation.Test{path: "/x/y", value: "Bob"}
      iex> target = %{"x" => %{"y" => "Bob"}}
      iex> Jsonpatch.Operation.apply_op(test, target)
      %{"x" => %{"y" => "Bob"}}
  """

  alias Jsonpatch.Operation
  alias Jsonpatch.Operation.Test
  alias Jsonpatch.PathUtil

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}

  defimpl Operation do
    @spec apply_op(Test.t(), list() | map() | Jsonpatch.error(), keyword()) :: map()
    def apply_op(_, {:error, _, _} = error, _opts), do: error

    def apply_op(%Test{path: path, value: value}, target, opts) do
      case PathUtil.get_final_destination(target, path, opts) |> do_test(value) do
        true -> target
        false -> {:error, :test_failed, "Expected value '#{value}' at '#{path}'"}
        {:error, _, _} = error -> error
      end
    end

    # ===== ===== PRIVATE ===== =====

    defp do_test({%{} = target, last_fragment}, value) do
      Map.get(target, last_fragment) == value
    end

    defp do_test({target, last_fragment}, value) when is_list(target) do
      case Integer.parse(last_fragment) do
        {index, _} ->
          case Enum.fetch(target, index) do
            {:ok, target_val} -> target_val == value
            :error -> {:error, :invalid_index, last_fragment}
          end

        :error ->
          {:error, :invalid_index, last_fragment}
      end
    end
  end
end
