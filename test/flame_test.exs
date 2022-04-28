defmodule FlameTest do
  use ExUnit.Case, async: true
  doctest Flame

  # test "token/0 returns a Auth token" do
  #   assert {:ok, %{}} = Flame.token()
  # end

  test "project/0 returns the project name" do
    assert Flame.project() == "flame-test-project"
  end

  test "credentials/0 loads Google Service Account JSON" do
    assert {:ok,
            %{
              "client_id" => _,
              "private_key" => _,
              "project_id" => _,
              "type" => "service_account"
            }} = Flame.credentials()
  end

  test "get_env/0 loads a configuration as a list" do
    assert Flame.get_env() |> Keyword.has_key?(:project)
    assert Flame.get_env() |> Keyword.has_key?(:credentials)
  end
end
