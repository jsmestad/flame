defmodule Flame.ProviderInfo do
  @moduledoc """
  {
  "providerId": String.t(),
  "displayName": String.t(),
  "photoUrl": String.t(),
  "federatedId": String.t(),
  "email": String.t(),
  "rawId": String.t(),
  "screenName": String.t(),
  "phoneNumber": String.t()
  }
  """

  defstruct [
    :provider_id,
    :display_name,
    :photo_url,
    :federated_id,
    :email,
    :raw_id,
    :screen_name,
    :phone_number
  ]

  use Ecto.Type
  @impl true
  def type, do: :map

  @impl true
  def cast(%{} = params) do
    result =
      changeset(%__MODULE__{}, params)
      |> Ecto.Changeset.apply_action(:create)

    case result do
      {:error, _} -> :error
      _ -> result
    end
  end

  def cast(_), do: :error

  @impl true
  def load(data) when is_map(data) do
    data =
      for {key, val} <- data do
        {String.to_existing_atom(key), val}
      end

    {:ok, struct!(__MODULE__, data)}
  end

  @impl true
  def dump(%__MODULE__{} = data), do: {:ok, Map.from_struct(data)}
  def dump(_), do: :error

  @type t :: %{
          provider_id: String.t(),
          display_name: String.t(),
          photo_url: String.t(),
          federated_id: String.t(),
          email: String.t(),
          raw_id: String.t(),
          screen_name: String.t(),
          phone_number: String.t()
        }

  def new(params) do
    changeset(%__MODULE__{}, params)
    |> Ecto.Changeset.apply_action(:create)
  end

  def changeset(obj, params) do
    types = %{
      provider_id: :string,
      display_name: :string,
      photo_url: :string,
      federated_id: :string,
      email: :string,
      raw_id: :string,
      screen_name: :string,
      phone_number: :string
    }

    {obj, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
  end
end
