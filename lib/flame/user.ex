defmodule Flame.User do
  @moduledoc """
    Reference: https://cloud.google.com/identity-platform/docs/reference/rest/v1/UserInfo

    %{
      "createdAt" => "1484124142000",
      "customAuth" => false,
      "disabled" => false,
      "displayName" => "John Doe",
      "email" => "user@example.com",
      "emailVerified" => false,
      "lastLoginAt" => "1484628946000",
      "localId" => "ZY1rJK0...",
      "passwordHash" => "...",
      "passwordUpdatedAt" => 1.484_124_177e12,
      "photoUrl" => "https://lh5.googleusercontent.com/.../photo.jpg",
      "providerUserInfo" => [
        %{
          "displayName" => "John Doe",
          "email" => "user@example.com",
          "federatedId" => "user@example.com",
          "photoUrl" => "http://localhost:8080/img1234567890/photo.png",
          "providerId" => "password",
          "rawId" => "user@example.com",
          "screenName" => "user@example.com"
        }
      ],
      "validSince" => "1484124177"
    }
  """

  @type t :: %__MODULE__{
          created_at: integer,
          custom_auth: boolean,
          disabled: boolean,
          display_name: String.t(),
          email: String.t(),
          email_verified: boolean,
          last_login_at: integer,
          local_id: String.t(),
          password_hash: String.t(),
          password_updated_at: float(),
          photo_url: String.t(),
          provider_user_info: [Flame.ProviderInfo.t()],
          valid_since: integer
        }

  defstruct [
    :created_at,
    :custom_auth,
    :disabled,
    :display_name,
    :email,
    :email_verified,
    :last_login_at,
    :local_id,
    :password_hash,
    :password_updated_at,
    :photo_url,
    :provider_user_info,
    :valid_since
  ]

  @spec new(map) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new(params) do
    data = Flame.Helpers.transform_params(params)

    types = %{
      created_at: :integer,
      custom_auth: :boolean,
      disabled: :boolean,
      display_name: :string,
      email: :string,
      email_verified: :boolean,
      last_login_at: :integer,
      local_id: :string,
      password_hash: :string,
      password_updated_at: :float,
      photo_url: :string,
      provider_user_info: {:array, Flame.ProviderInfo},
      valid_since: :integer
    }

    {%__MODULE__{}, types}
    |> Ecto.Changeset.cast(data, Map.keys(types))
    |> Ecto.Changeset.apply_action(:create)
  end
end
