defmodule Jsonpatch.Error do
  @moduledoc """
  Describe an error that occured while patching.
  """

  @enforce_keys [:patch, :patch_index, :reason]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          patch: Jsonpatch.t(),
          patch_index: non_neg_integer(),
          reason: Jsonpatch.Types.error_reason()
        }
end
