defmodule Jsonpatch.Operation.Remove do
  @enforce_keys [:path]
  defstruct [:path]
end
