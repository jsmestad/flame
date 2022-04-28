defmodule Flame do
  @moduledoc """
  Documentation for `Flame`.
  """

  @type user :: Flame.User.t()
  @type provider_info :: Flame.ProviderInfo.t()

  @spec token :: {:ok, map}
  def token do
    Flame.Application.service_name() |> Goth.fetch()
  end

  @spec get_env :: list
  def get_env do
    Application.get_env(:flame, Flame, project: nil, credentials: nil)
    |> Keyword.put_new(:adapter, {Tesla.Adapter.Finch, name: Flame.Application.pool_name()})
  end

  @spec project :: String.t() | no_return
  def project do
    case get_env() |> Keyword.get(:project) do
      nil -> raise "Missing :project configuration"
      val -> val
    end
  end

  @spec credentials :: {:ok, map} | :error
  def credentials do
    case get_env() |> Keyword.get(:credentials) do
      nil -> :error
      val -> Jason.decode(val)
    end
  end

  @spec private_key :: {:ok, String.t()} | :error
  def private_key do
    case credentials() do
      {:ok, map} -> Map.fetch(map, "private_key")
      _ -> :error
    end
  end

  @spec service_account :: {:ok, String.t()} | :error
  def service_account do
    case credentials() do
      {:ok, map} -> Map.fetch(map, "client_email")
      _ -> :error
    end
  end
end
