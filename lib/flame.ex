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

  @doc """
  Checks the token for validity against session cookies or tokens.

  It does not check for revoked or disabled users.
  """
  @spec verify(String.t() | Flame.IdToken.t() | Flame.SessionCookie.t()) ::
          {:ok, Flame.IdToken.t() | Flame.SessionCookie.t()} | {:error, any}
  def verify(str) when is_binary(str) do
    case JOSE.JWT.peek_payload(str) do
      %{fields: %{"email_verified" => _}} -> Flame.IdToken.verify(str)
      %{fields: %{}} -> Flame.SessionCookie.verify(str)
    end
  end

  def verify(%Flame.IdToken{} = token) do
    Flame.IdToken.verify(token)
  end

  def verify(%Flame.SessionCookie{} = cookie) do
    Flame.SessionCookie.verify(cookie)
  end

  @spec get_env :: list
  def get_env do
    Application.get_env(:flame, Flame, project: nil, credentials: nil)
    |> Keyword.put_new(:adapter, {Tesla.Adapter.Finch, name: Flame.Application.pool_name()})
    |> Keyword.put_new(:client, {Flame.Client, :new, []})
  end

  @spec client :: Tesla.Client.t() | no_return
  def client do
    case get_env() |> Keyword.get(:client) do
      {mod, fun, args} -> Kernel.apply(mod, fun, args)
      _ -> raise "Invalid :client configuration"
    end
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
