defmodule Flame.Application do
  @moduledoc false

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    issuer = Flame.get_env() |> Keyword.fetch!(:issuer)
    cookie_issuer = Flame.get_env() |> Keyword.fetch!(:cookie_issuer)
    Application.put_env(:ex_firebase_auth, :issuer, issuer)
    Application.put_env(:ex_firebase_auth, :cookie_issuer, cookie_issuer)

    children = [
      goth_spec()
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec pool_name :: atom()
  def pool_name, do: Flame.Finch

  @spec service_name :: atom()
  def service_name, do: Flame.TokenService

  defp goth_spec do
    name = service_name()

    case Flame.credentials() do
      :error ->
        %{id: name, start: {Function, :identity, [:ignore]}}

      {:ok, %{} = credentials} ->
        source =
          {:service_account, credentials,
           [
             scopes: [
               "https://www.googleapis.com/auth/identitytoolkit"
             ]
           ]}

        {Goth, name: name, source: source, http_client: {:finch, []}}
    end
  end
end
