# JQ
Elixir wrapper for [jq](https://stedolan.github.io/jq/). 
Note: you must have jq installed and avalible in your `$PATH`

## Installation
* Install jq `brew install jq`
* add `jq` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jq, "~> 1.0"}
  ]
end
```

## Usage
```bash
iex> JQ.query(%{key: "value"}, ".key")
{:ok, "value"}

iex> JQ.query!(%{key: "value"}, ".key")
"value"
```

* [https://hexdocs.pm/jq](https://hexdocs.pm/jq).

