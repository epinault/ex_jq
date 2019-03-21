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
  require Logger

  def query(payload, query, options \\ [])

  @spec query(any(), String.t(), list()) :: {:ok, any()} | {:error, :cmd | :unknown}
  def query(payload, query, _options) do
    with {:ok, _} <- JQ.Query.validate(query),
         {:ok, json} <- Poison.encode(payload),
         {:ok, fd, file_path} <- Temp.open(),
         :ok <- IO.write(fd, json),
         :ok <- File.close(fd),
         {value, code} when code == 0 <-
           System.cmd("jq", [query, file_path], stderr_to_stdout: true) do
      File.rm!(file_path)
      Poison.decode(value)
    else
      {message, code} when is_integer(code) and code != 0 ->
        Logger.error(cmd_error(message, code))
        {:error, :cmd}

      error ->
        Logger.error("Unexpected error. #{inspect(error)}")
        {:error, :unknown}
    end
  end

  def query!(payload, query, options \\ [])

  @spec query!(any(), String.t(), list()) :: any()
  def query!(payload, query, _options) do
    json = Poison.encode!(payload)
    {fd, file_path} = Temp.open!()
    IO.write(fd, json)
    File.close(fd)

    case System.cmd("jq", [query, file_path], stderr_to_stdout: true) do
      {value, code} when is_integer(code) and code == 0 ->
        File.rm!(file_path)
        result = Poison.decode!(value)

        unless result do
          raise "NO_VALUE_FOUND"
        end

        result

      {message, code} when is_integer(code) and code != 0 ->
        raise cmd_error(message, code)

      error ->
        raise "UNKNOWN #{inspect(error)}"
    end
  end

  defp cmd_error(message, code) do
    """
    Error executing jq bash command. 
      exit code: #{inspect(code)}
      message: #{inspect(message)}
    """
  end
end
