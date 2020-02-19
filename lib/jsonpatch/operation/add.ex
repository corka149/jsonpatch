defmodule Jsonpatch.Operation.Add do
  @enforce_keys [:path, :value]
  defstruct [:path, :value]
end
