defmodule Flame.IdToken do
  @moduledoc """
  See [JWT](https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library)
  """
  @type t :: %__MODULE__{
          aud: String.t(),
          auth_time: DateTime.t(),
          email: String.t() | nil,
          email_verified: boolean,
          exp: DateTime.t(),
          firebase: map,
          iat: DateTime.t(),
          iss: String.t(),
          name: String.t() | nil,
          provider: String.t(),
          sub: String.t(),
          value: token
        }

  @type user_id :: String.t()
  @type email :: String.t()
  @type reason :: String.t()
  @type type :: :cookie | :id_token
  @type token :: String.t()

  @enforce_keys [
    :aud,
    :auth_time,
    :email,
    :email_verified,
    :exp,
    :firebase,
    :iat,
    :iss,
    :name,
    :sub,
    :provider,
    :value
  ]
  defstruct [
    :aud,
    :auth_time,
    :email,
    :email_verified,
    :exp,
    :firebase,
    :iat,
    :iss,
    :name,
    :sub,
    :provider,
    :value
  ]

  @spec new!(token) :: t | no_return
  def new!(token) do
    %JOSE.JWT{fields: fields} = JOSE.JWT.peek_payload(token)
    new!(token, fields)
  end

  @spec new!(token, map) :: t | no_return
  def new!(token, fields) do
    struct!(__MODULE__, %{
      aud: fields["aud"],
      auth_time: DateTime.from_unix!(fields["auth_time"]),
      email: fields["email"],
      email_verified: fields["email_verified"],
      exp: DateTime.from_unix!(fields["exp"]),
      firebase: fields["firebase"],
      iat: DateTime.from_unix!(fields["iat"]),
      iss: fields["iss"],
      name: fields["name"],
      sub: fields["sub"],
      provider: fields["firebase"]["sign_in_provider"],
      value: token
    })
  end

  @doc """
  Checks the token for validity against session cookies or tokens.

  It does not check for revoked or disabled users.
  """
  @spec verify(String.t() | t) :: {:ok, t} | {:error, any}
  def verify(token) when is_binary(token) do
    case ExFirebaseAuth.Token.verify_token(token) do
      {:ok, _user_id, %{fields: fields}} -> {:ok, new!(token, fields)}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify(%__MODULE__{value: token}), do: verify(token)
end
