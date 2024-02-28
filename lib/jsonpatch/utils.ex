defmodule Jsonpatch.Utils do
  @moduledoc false

  alias Jsonpatch.Types

  @default_opts_keys :strings

  @doc """
  Split a path into its fragments

  ## Examples

    iex> path = "/a/b/c"
    iex> Jsonpatch.Utils.split_path(path)
    {:ok, ["a", "b", "c"]}
  """
  @spec split_path(String.t()) :: {:ok, [String.t(), ...] | :root} | Types.error()
  def split_path("/" <> path) do
    fragments =
      path
      |> String.split("/")
      |> Enum.map(&unescape/1)

    {:ok, fragments}
  end

  def split_path(""), do: {:ok, :root}

  def split_path(path), do: {:error, {:invalid_path, path}}

  @doc """
  Join path fragments

  ## Examples

    iex> fragments = ["a", "b", "c"]
    iex> Jsonpatch.Utils.join_path(fragments)
    "/a/b/c"
  """
  @spec join_path(fragments :: [Types.casted_fragment(), ...]) :: String.t()
  def join_path([_ | _] = fragments) do
    fragments =
      fragments
      |> Enum.map(&to_string/1)
      |> Enum.map(&escape/1)

    "/" <> Enum.join(fragments, "/")
  end

  @doc """
  Cast a path fragment according to the target type.

  ## Examples

    iex> Jsonpatch.Utils.cast_fragment("0", ["path"], ["x", "y"], [])
    {:ok, 0}

    iex> Jsonpatch.Utils.cast_fragment("-", ["path"], ["x", "y"], [])
    {:ok, :-}

    iex> Jsonpatch.Utils.cast_fragment("0", ["path"], %{"0" => "zero"}, [])
    {:ok, "0"}
  """
  @spec cast_fragment(
          fragment :: String.t(),
          path :: [Types.casted_fragment()],
          target :: Types.json_container(),
          Types.opts()
        ) :: {:ok, Types.casted_fragment()} | Types.error()
  def cast_fragment(fragment, path, target, opts) when is_list(target) do
    keys = Keyword.get(opts, :keys, @default_opts_keys)

    case keys do
      {:custom, custom_fn} ->
        case custom_fn.(fragment, path, target, opts) do
          {:ok, _} = ok -> ok
          :error -> {:error, {:invalid_path, path ++ [fragment]}}
        end

      _ ->
        cast_index(fragment, path, target)
    end
  end

  def cast_fragment(fragment, path, target, opts) when is_map(target) do
    keys = Keyword.get(opts, :keys, @default_opts_keys)

    case keys do
      :strings ->
        {:ok, fragment}

      :atoms ->
        {:ok, String.to_atom(fragment)}

      :atoms! ->
        case string_to_existing_atom(fragment) do
          {:ok, _} = ok -> ok
          :error -> {:error, {:invalid_path, path ++ [fragment]}}
        end

      {:custom, custom_fn} ->
        case custom_fn.(fragment, path, target, opts) do
          {:ok, _} = ok -> ok
          :error -> {:error, {:invalid_path, path ++ [fragment]}}
        end
    end
  end

  @doc """
  Uses a JSON patch path to get the last map/list that this path references.

  ## Examples

      iex> path = "/a/b/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
      iex> Jsonpatch.Utils.get_destination(target, path)
      {:ok, {%{"d" => 1}, "d"}}

      iex> # Invalid path
      iex> path = "/a/e/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"d" => 1}}}}
      iex> Jsonpatch.Utils.get_destination(target, path)
      {:error, {:invalid_path, ["a", "e"]}}

      iex> path = "/a/b/1/d"
      iex> target = %{"a" => %{"b" => [true, %{"d" => 1}]}}
      iex> Jsonpatch.Utils.get_destination(target, path)
      {:ok, {%{"d" => 1}, "d"}}

      iex> path = "/a/b/1"
      iex> target = %{"a" => %{"b" => [true, %{"d" => 1}]}}
      iex> Jsonpatch.Utils.get_destination(target, path)
      {:ok, {[true, %{"d" => 1}], 1}}

      iex> # Invalid path
      iex> path = "/a/b/42/d"
      iex> target = %{"a" => %{"b" => [true, %{"d" => 1}]}}
      iex> Jsonpatch.Utils.get_destination(target, path)
      {:error, {:invalid_path, ["a", "b", "42"]}}
  """

  @spec get_destination(
          target :: Types.json_container(),
          path :: String.t(),
          Types.opts()
        ) ::
          {:ok, {Types.json_container(), last_fragment :: Types.casted_fragment()}}
          | Types.error()
  def get_destination(target, path, opts \\ [])

  def get_destination(target, "", _opts) do
    {:ok, {target, :root}}
  end

  def get_destination(target, path, opts) do
    with {:ok, fragments} <- split_path(path) do
      find_destination(target, [], fragments, opts)
    end
  end

  @doc """
  Updatest a map/list reference by a given JSON patch path with the new destination.

  ## Examples

      iex> path = "/a/b/c/d"
      iex> target = %{"a" => %{"b" => %{"c" => %{"xx" => 0, "d" => 1}}}}
      iex> Jsonpatch.Utils.update_destination(target, %{"e" => 1}, path)
      {:ok, %{"a" => %{"b" => %{"c" => %{"e" => 1}}}}}

      iex> path = "/a/b/1"
      iex> target = %{"a" => %{"b" => [0, 1, 2]}}
      iex> Jsonpatch.Utils.update_destination(target, 9999, path)
      {:ok, %{"a" => %{"b" => 9999}}}
  """
  @spec update_destination(
          target :: Types.json_container(),
          value :: term(),
          String.t(),
          Types.opts()
        ) ::
          {:ok, Types.json_container()} | Types.error()
  def update_destination(target, value, path, opts \\ []) do
    with {:ok, fragments} <- split_path(path) do
      do_update_destination(target, value, [], fragments, opts)
    end
  end

  @doc """
  Unescape `~1` to  `/` and `~0` to `~`.
  """
  @spec unescape(fragment :: String.t() | integer()) :: String.t()
  def unescape(fragment) when is_binary(fragment) do
    fragment
    |> String.replace("~0", "~")
    |> String.replace("~1", "/")
  end

  @doc """
  Escape `/` to `~1 and `~` to `~0`.
  """
  @spec escape(fragment :: String.t() | integer()) :: String.t()
  def escape(fragment) when is_binary(fragment) do
    fragment
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
  end

  @doc """
  Updates a list with the given update_fn while respecting Jsonpatch errors.
  In case uodate_fn returns an error then update_at will also return this error.
  When the update_fn succeeds it will return the list.
  """
  @spec update_at(
          target :: list(),
          index :: non_neg_integer(),
          path :: [Types.casted_fragment()],
          update_fn :: (item :: term() -> updated_item :: term())
        ) :: {:ok, list()} | Types.error()
  def update_at(target, index, path, update_fn) do
    case fetch(target, index) do
      {:ok, old_val} ->
        do_update_at(target, index, old_val, update_fn)

      {:error, :invalid_path} ->
        {:error, {:invalid_path, path ++ [to_string(index)]}}
    end
  end

  @spec fetch(Types.json_container(), Types.casted_fragment()) ::
          {:ok, term()} | {:error, :invalid_path}
  def fetch(_list, :-), do: {:error, :invalid_path}

  def fetch(container, key) do
    mod =
      cond do
        is_list(container) -> Enum
        is_map(container) -> Map
      end

    case mod.fetch(container, key) do
      # coveralls-ignore-start
      :error -> {:error, :invalid_path}
      # coveralls-ignore-stop
      {:ok, val} -> {:ok, val}
    end
  end

  @spec cast_index(
          fragment :: String.t(),
          path :: [Types.casted_fragment()],
          target :: Types.json_container()
        ) :: {:ok, Types.casted_fragment()} | Types.error()
  def cast_index(fragment, path, target) do
    case fragment do
      "-" ->
        {:ok, :-}

      _ ->
        case to_index(fragment, length(target)) do
          {:ok, index} -> {:ok, index}
          {:error, :invalid_path} -> {:error, {:invalid_path, path ++ [fragment]}}
        end
    end
  end

  defp to_index(unparsed_index, list_lenght) do
    case Integer.parse(unparsed_index) do
      {index, _} when 0 <= index and index <= list_lenght -> {:ok, index}
      {_index_out_of_range, _} -> {:error, :invalid_path}
      :error -> {:error, :invalid_path}
    end
  end

  defp find_destination(%{} = target, path, [fragment], opts) do
    with {:ok, fragment} <- cast_fragment(fragment, path, target, opts) do
      {:ok, {target, fragment}}
    end
  end

  defp find_destination(target, path, [fragment], opts) when is_list(target) do
    with {:ok, index} <- cast_fragment(fragment, path, target, opts) do
      {:ok, {target, index}}
    end
  end

  defp find_destination(%{} = target, path, [fragment | tail], opts) do
    with {:ok, fragment} <- cast_fragment(fragment, path, target, opts),
         %{^fragment => sub_target} <- target do
      find_destination(sub_target, path ++ [fragment], tail, opts)
    else
      %{} ->
        {:error, {:invalid_path, path ++ [fragment]}}

      # coveralls-ignore-start
      {:error, _} = error ->
        error
        # coveralls-ignore-stop
    end
  end

  defp find_destination(target, path, [fragment | tail], opts) when is_list(target) do
    with {:ok, index} <- cast_fragment(fragment, path, target, opts) do
      val = Enum.fetch!(target, index)
      find_destination(val, path ++ [fragment], tail, opts)
    end
  end

  defp do_update_destination(_target, value, _path, :root, _opts) do
    {:ok, value}
  end

  defp do_update_destination(_target, value, _path, [_fragment], _opts) do
    {:ok, value}
  end

  defp do_update_destination(%{} = target, value, path, [destination, _last_ele], opts) do
    with {:ok, destination} <- cast_fragment(destination, path, target, opts) do
      {:ok, Map.replace!(target, destination, value)}
    end
  end

  defp do_update_destination(target, value, path, [destination, _last_ele], opts)
       when is_list(target) do
    with {:ok, index} <- cast_fragment(destination, path, target, opts) do
      {:ok, List.replace_at(target, index, value)}
    end
  end

  defp do_update_destination(%{} = target, value, path, [fragment | tail], opts) do
    with {:ok, fragment} <- cast_fragment(fragment, path, target, opts),
         %{^fragment => sub_target} <- target,
         {:ok, updated_val} <-
           do_update_destination(sub_target, value, path ++ [fragment], tail, opts) do
      {:ok, %{target | fragment => updated_val}}
    else
      %{} -> {:error, {:invalid_path, path ++ [fragment]}}
      {:error, _} = error -> error
    end
  end

  defp do_update_destination(target, value, path, [fragment | tail], opts) when is_list(target) do
    with {:ok, index} <- cast_fragment(fragment, path, target, opts) do
      update_fn = &do_update_destination(&1, value, path ++ [fragment], tail, opts)
      update_at(target, index, path, update_fn)
    end
  end

  defp do_update_at(target, index, old_val, update_fn) do
    case update_fn.(old_val) do
      {:error, _} = error -> error
      {:ok, new_val} -> {:ok, List.replace_at(target, index, new_val)}
    end
  end

  defp string_to_existing_atom(data) when is_binary(data) do
    {:ok, String.to_existing_atom(data)}
  rescue
    ArgumentError -> :error
  end
end
