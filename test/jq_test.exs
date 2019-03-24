defmodule JQTest do
  use ExUnit.Case
  doctest JQ

  alias JQ.{MaxByteSizeExceededException, NoResultException, SystemCmdException}

  describe "JQ.query" do
    test "simple JQ querry" do
      assert {:ok, "spencer"} == JQ.query(%{name: "spencer"}, ".name")
    end

    test "handle empty result" do
      assert {:ok, nil} == JQ.query(%{name: "spencer"}, ".age")
    end

    test "string keys" do
      assert {:ok, %{"key" => 1}} == JQ.query([%{key: 1}], ".[0]")
    end

    test "filter and rename keys" do
      data = [%{first_name: "spencer", age: 20}]
      assert {:ok, %{"name" => "spencer"}} == JQ.query(data, ".[0] | {name: .first_name}")
    end

    test "complex jq query" do
      data = %{
        "Phones" => [
          %{
            "PhoneType" => "Mobile",
            "Number" => "5555555555"
          },
          %{
            "PhoneType" => "Work",
            "Number" => "1111111111"
          }
        ]
      }

      assert {:ok, "5555555555"} ==
               JQ.query(data, ".Phones[] | select(.PhoneType == \"Mobile\").Number")
    end

    test "complex return type" do
      assert {:ok, ["spencer", "alex"]} == JQ.query(%{names: ["spencer", "alex"]}, ".names")
    end

    test "protects against bash injection" do
      assert {:error, :cmd} = JQ.query(%{names: ["spencer", "alex"]}, "| say hello")
    end

    test "returns an error when max_byte_size is exceeded" do
      assert {:error, :max_byte_size_exceeded} =
               JQ.query(%{names: ["spencer", "alex"]}, ".names", max_byte_size: 1)
    end
  end

  describe "JQ.query!" do
    test "simple JQ querry" do
      assert "spencer" == JQ.query!(%{name: "spencer"}, ".name")
    end

    test "handle empty result" do
      assert_raise NoResultException, fn ->
        JQ.query!(%{name: "spencer"}, ".age")
      end
    end

    test "protects against bash injection" do
      assert_raise SystemCmdException, fn ->
        JQ.query!(%{names: ["spencer", "alex"]}, "| say hello")
      end
    end

    test "respects max_byte_size option" do
      assert_raise MaxByteSizeExceededException, fn ->
        JQ.query!(%{names: ["spencer", "alex"]}, ".names", max_byte_size: 1)
      end
    end
  end
end
