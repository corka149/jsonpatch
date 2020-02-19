defmodule Jsonpatch.Operation.Replace do
  @enforce_keys [:path, :value]
  defstruct [:path, :value]
end
