defmodule Jsonpatch.Operation do
  @moduledoc """
  Defines behaviour for apply a patch to a struct.
  """

  alias Jsonpatch.Operation.Add
  alias Jsonpatch.Operation.Remove
  alias Jsonpatch.Operation.Replace

  @typedoc """
  A valid Jsonpatch operation by RFC 6902
  """
  @type t :: Add.t() | Remove.t() | Replace.t()

  @callback apply(Jsonpatch.Operation.t) :: map()
end
