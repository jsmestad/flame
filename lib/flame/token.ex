defmodule Flame.Token do
  @type t :: String.t()
  @type user_id :: String.t()
  @type email :: String.t()
  @type reason :: String.t()
  @type type :: :cookie | :id_token

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
    :user_id,
    :value
  ]

  def new(token) do
    %JOSE.JWT{fields: fields} = JOSE.JWT.peek_payload(token)
    new(token, fields)
  end

  def new(token, fields) do
    struct(__MODULE__, %{
      aud: fields["aud"],
      auth_time: fields["auth_time"],
      email: fields["email"],
      email_verified: fields["email_verified"],
      exp: fields["exp"],
      firebase: fields["firebase"],
      iat: fields["iat"],
      iss: fields["iss"],
      name: fields["name"],
      sub: fields["sub"],
      user_id: fields["user_id"],
      value: token
    })
  end

  @doc """
  Checks the token for validity against session cookies or tokens.

  It does not check for revoked or disabled users.
  """
  @spec verify(t) :: {:ok, t} | {:error, reason}
  def verify(token) when is_binary(token) do
    case verify(:cookie, token) do
      {:error, "Signed by invalid issuer"} -> verify(:id_token, token)
      val -> val
    end
  end

  @doc """
  Checks the validity of the cookie itself.

  It does not check for revoked or disabled users, use verify_session/2 for that.
  """
  @spec verify(type, t) :: {:ok, t} | {:error, reason}
  def verify(:cookie, cookie) do
    case ExFirebaseAuth.Cookie.verify_cookie(cookie) do
      {:ok, _user_id, %{fields: fields}} -> {:ok, new(cookie, fields)}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify(:id_token, token) do
    case ExFirebaseAuth.Token.verify_token(token) do
      {:ok, _user_id, %{fields: fields}} -> {:ok, new(token, fields)}
      {:error, reason} -> {:error, reason}
    end
  end
end
