defmodule Jsonpatch.Types do
  @moduledoc """
  Types
  """

  @type error :: {:error, error_reason()}
  @type error_reason ::
          {:invalid_spec, String.t()}
          | {:invalid_path, [casted_fragment()]}
          | {:test_failed, String.t()}

  @type json_container :: map() | list()

  @type convert_fn ::
          (fragment :: term(), target_path :: [term()], target :: json_container(), opts() ->
             {:ok, converted_fragment :: term()} | :error)

  @typedoc """
  Keys options:

  - `:strings` (default) - decodes path fragments as binary strings
  - `:atoms` - path fragments are converted to atoms
  - `:atoms!` - path fragments are converted to existing atoms
  - `{:custom, convert_fn}` - path fragments are converted with `convert_fn`
  """
  @type opt_keys :: :strings | :atoms | {:custom, convert_fn()}

  @typedoc """
  Types options:

  - `:keys` - controls how path fragments are decoded.
  """
  @type opts :: [{:keys, opt_keys()}]

  @type casted_array_index :: :- | non_neg_integer()
  @type casted_object_key :: atom() | String.t()
  @type casted_fragment :: casted_array_index() | casted_object_key()
end
