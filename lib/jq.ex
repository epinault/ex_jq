defmodule JQ do
  @moduledoc """
  Provides capability to run jq queries on elixir structures.
  [jq docs](https://stedolan.github.io/jq/)

  ## Examples

      iex> JQ.query(%{key: "value"}, ".key")
      {:ok, "value"}

      iex> JQ.query!(%{key: "value"}, ".key")
      "value"

  """
  alias JQ.{MaxByteSizeExceededException, NoResultException, SystemCmdException, UnknownException}
  require Logger

  @default_options %{max_byte_size: nil}

  @doc ~S"""
  Execute a jq query on an elixir structure.

  Internally invokes `JQ.query!/3` and rescues from all exceptions.

  If a `JQ.NoResultException` is raised, `{:ok, nil}` is returned
  """
  def query(payload, query, options \\ [])

  @spec query(any(), String.t(), list()) ::
          {:ok, any()} | {:error, :cmd | :unknown | :max_byte_size_exceeded}
  def query(payload, query, options) do
    {:ok, query!(payload, query, options)}
  rescue
    _ in NoResultException ->
      {:ok, nil}

    e in [SystemCmdException, UnknownException] ->
      Logger.warning(e.message)
      {:error, :cmd}

    e in MaxByteSizeExceededException ->
      Logger.warning(e.message)
      {:error, :max_byte_size_exceeded}

    error ->
      Logger.warning("unknown error. error: #{inspect(error)}")
      {:error, :unknown}
  end

  @doc ~S"""
  Execute a jq query on an elixir structure.

  * `payload` is any elixir structure
  * `query` a jq query as a string

  Internally this function encodes the `payload` into JSON, writes the JSON to
  a temporary file, invokes the jq executable on the temporary file with the supplied
  jq `query`.

  The result is then decoded from JSON back into an elixir structure.
  The temporary file is removed, regardless of the outcome. `System.cmd/3` is called
  with the `:stderr_to_stdout` option.

  ## Options
    * `:max_byte_size` - integer representing the maximum number of bytes allowed for the payload, defaults to `nil`.

  ## Error reasons
  * `JQ.MaxByteSizeExceededException` - when the byte_size of the encoded elixir structure is greater than the `:max_byte_size` value
  * `JQ.SystemCmdException` - when System.cmd/3 returns a non zero exit code
  * `JQ.NoResultException` - when no result was returned
  * `JQ.UnknownException` - when System.cmd/3 returns any other error besides those already handled
  * `Poison.EncodeError` - when there is an error encoding `payload`
  * `Poison.DecodeError` - when there is an error decoding the jq query result
  * `Temp.Error` - when there is an error creating a temporary file
  * `File.Error` - when there is an error removing a temporary file
  """
  def query!(payload, query, options \\ [])

  @spec query!(any(), String.t(), list()) :: any()
  def query!(payload, query, options) do
    %{max_byte_size: max_byte_size} = Enum.into(options, @default_options)

    json = payload |> Poison.encode!() |> validate_max_byte_size(max_byte_size)

    {fd, file_path} = Temp.open!()
    IO.write(fd, json)
    File.close(fd)

    try do
      case System.cmd("jq", [query, file_path], stderr_to_stdout: true) do
        {_, code} = error when is_integer(code) and code != 0 ->
          raise(SystemCmdException, result: error, command: "jq", args: [query, file_path])

        {value, code} when is_integer(code) and code == 0 ->
          case Poison.decode!(value) do
            nil ->
              raise(NoResultException)

            result ->
              result
          end

        error ->
          raise(UnknownException, error)
      end
    after
      File.rm!(file_path)
    end
  end

  defp validate_max_byte_size(json, max_byte_size)
       when is_integer(max_byte_size) and byte_size(json) > max_byte_size do
    raise(MaxByteSizeExceededException, size: byte_size(json), max_byte_size: max_byte_size)
  end

  defp validate_max_byte_size(json, _), do: json
end
