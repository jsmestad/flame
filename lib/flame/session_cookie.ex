defmodule Flame.SessionCookie do
  @moduledoc """
  See [JWT](https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library)
  """
  @type t :: %__MODULE__{
          aud: String.t(),
          auth_time: DateTime.t(),
          exp: DateTime.t(),
          firebase: map,
          iat: DateTime.t(),
          iss: String.t(),
          provider: String.t(),
          sub: String.t(),
          value: cookie
        }

  @type user_id :: String.t()
  @type email :: String.t()
  @type reason :: String.t()
  @type type :: :cookie | :id_token
  @type cookie :: String.t()

  @enforce_keys [
    :aud,
    :auth_time,
    :exp,
    :firebase,
    :iat,
    :iss,
    :sub,
    :provider,
    :value
  ]
  defstruct [
    :aud,
    :auth_time,
    :exp,
    :firebase,
    :iat,
    :iss,
    :sub,
    :provider,
    :value
  ]

  @spec new(cookie) :: t | no_return
  def new(cookie) do
    %JOSE.JWT{fields: fields} = JOSE.JWT.peek_payload(cookie)
    new(cookie, fields)
  end

  @spec new(cookie, map) :: t
  def new(cookie, fields) do
    struct!(__MODULE__, %{
      aud: fields["aud"],
      auth_time: DateTime.from_unix!(fields["auth_time"]),
      exp: DateTime.from_unix!(fields["exp"]),
      firebase: fields["firebase"],
      iat: DateTime.from_unix!(fields["iat"]),
      iss: fields["iss"],
      sub: fields["sub"],
      provider: fields["firebase"]["sign_in_provider"],
      value: cookie
    })
  end

  def from_unix!(nil), do: nil
  def from_unix!(val), do: DateTime.from_unix!(val)

  @doc """
  Checks the session cookie for validity.

  It does not check for revoked or disabled users.
  """
  @spec verify(String.t() | t) :: {:ok, t} | {:error, any}
  def verify(cookie) when is_binary(cookie) do
    case ExFirebaseAuth.Cookie.verify_cookie(cookie) do
      {:ok, _user_id, %{fields: fields}} -> {:ok, new(cookie, fields)}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify(%__MODULE__{value: token}), do: verify(token)
end
