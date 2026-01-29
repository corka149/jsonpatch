defmodule Jsonpatch.Operation.Replace do
  @moduledoc """
  The replace module helps replacing values in maps and structs by paths.

  ## Examples

      iex> add = %Jsonpatch.Operation.Replace{path: "/a/b", value: 1}
      iex> target = %{"a" => %{"b" => 2}}
      iex> Jsonpatch.Operation.Replace.apply(add, target, [])
      {:ok, %{"a" => %{"b" => 1}}}
  """

  alias Jsonpatch.Operation.{Add, Remove, Replace}
  alias Jsonpatch.Types

  @enforce_keys [:path, :value]
  defstruct [:path, :value]
  @type t :: %__MODULE__{path: String.t(), value: any}

  @spec apply(Jsonpatch.t(), target :: Types.json_container(), Types.opts()) ::
          {:ok, Types.json_container()} | Types.error()
  def apply(%Replace{path: "", value: value}, _target, _opts) do
    {:ok, value}
  end

  def apply(%Replace{path: path, value: value}, target, opts) do
    remove_patch = %Remove{path: path}
    add_patch = %Add{value: value, path: path}

    with {:ok, res} <- Remove.apply(remove_patch, target, opts),
         {:ok, res} <- Add.apply(add_patch, res, opts) do
      {:ok, res}
    end
  end
end
