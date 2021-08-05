defmodule JsonpatchException do
  @moduledoc """
  JsonpatchException will be raised if a patch is applied with "!".
  """

  defexception [:message]

  @impl true
  def exception({:error, err_type, err_msg} = _error) do
    msg = "#{err_type}: '#{err_msg}'"
    %JsonpatchException{message: msg}
  end
end
