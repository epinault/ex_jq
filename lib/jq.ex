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

  def query(payload, query, options \\ [])

  @spec query(any(), String.t(), list()) :: {:ok, any()} | {:error, :cmd | :unknown}
  def query(payload, query, options) do
    {:ok, query!(payload, query, options)}
  rescue
    _ in NoResultException ->
      {:ok, nil}

    e in [SystemCmdException, UnknownException] ->
      Logger.warn(e.message)
      {:error, :cmd}

    e in MaxByteSizeExceededException ->
      Logger.warn(e.message)
      {:error, :max_byte_size_exceeded}
  end

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
          result = Poison.decode!(value)
          unless result, do: raise(NoResultException)
          result

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
