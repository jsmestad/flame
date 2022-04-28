defmodule Flame.Client do
  @moduledoc """
  The HTTP client for interacting with the Identity Platform API.
  """

  @spec new :: Tesla.Client.t()
  def new do
    Flame.get_env()
    |> Keyword.get(:base_url, "https://identitytoolkit.googleapis.com/v1/")
    |> new()
  end

  def new(base_url) do
    adapter = Keyword.fetch!(Flame.get_env(), :adapter)
    {:ok, token} = Flame.token()

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Telemetry,
      # Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers, [{"authorization", "Bearer " <> token.token}]}
    ]

    Tesla.client(middleware, adapter)
  end
end
