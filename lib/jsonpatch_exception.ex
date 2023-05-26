defmodule JsonpatchException do
  @moduledoc """
  JsonpatchException will be raised if a patch is applied with "!"
  and the patching fails.
  """

  defexception [:message]

  @impl true
  def exception({:error, %Jsonpatch.Error{patch_index: patch_index, reason: reason}} = _error) do
    msg = "patch ##{patch_index} failed, '#{inspect(reason)}'"
    %JsonpatchException{message: msg}
  end
end
