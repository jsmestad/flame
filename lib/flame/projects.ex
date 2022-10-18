defmodule Flame.Projects do
  @moduledoc """
  https://cloud.google.com/identity-platform/docs/reference/rest/v1/projects/
  """

  @type id_token :: Flame.IdToken.t()
  @type cookie :: Flame.SessionCookie.t()
  @type code :: String.t()
  @type provider :: String.t()
  @type local_id :: String.t()

  @doc """
  https://cloud.google.com/identity-platform/docs/reference/rest/v1/projects/createSessionCookie

  Duration must be at least 5 minutes, up to 14 days.
  """
  @spec create_session_cookie(id_token, integer) ::
          {:ok, cookie}
          | {:error, :invalid_id_token | :token_expired | :user_not_found}
  def create_session_cookie(_, duration) when duration < 5 * 60 do
    {:error, :duration_too_short}
  end

  def create_session_cookie(_, duration) when duration > 60 * 60 * 24 * 14 do
    {:error, :duration_too_long}
  end

  def create_session_cookie(%Flame.IdToken{} = id_token, duration) when is_integer(duration) do
    case do_request("createSessionCookie", %{
           idToken: id_token.value,
           duration: to_string(duration)
         }) do
      {:ok, %{"sessionCookie" => cookie}} -> {:ok, Flame.SessionCookie.new!(cookie)}
      {:error, :invalid_id_token} = err -> err
      {:error, :token_expired} = err -> err
      {:error, :user_not_found} = err -> err
    end
  end

  @doc """
  Checks the validity of the cookie itself.

  It does not check for revoked or disabled users, use verify_session/2 for that.
  """
  @spec verify_session(cookie) ::
          {:ok, Flame.SessionCookie.t()} | {:error, String.t()}
  def verify_session(%Flame.SessionCookie{} = cookie) do
    Flame.SessionCookie.verify(cookie)
  end

  @doc """
  Checks the validity of the cookie itself, like verify_session/1, but also makes an API
  call to Flame to check if the token has been revoked or the user is disabled.

  This was reverse-engineered from the Node.JS and Go Flame SDK.
  """
  @spec verify_session(cookie, opts :: [verify: boolean]) ::
          {:ok, cookie} | {:error, :cookie_revoked | :user_not_found}
  def verify_session(%Flame.SessionCookie{} = cookie, opts) do
    if Keyword.get(opts, :verify, true) do
      Flame.SessionCookie.verify(cookie)
      |> check_revoked()
    else
      Flame.SessionCookie.verify(cookie)
    end
  end

  def check_revoked({:error, _} = result), do: result

  def check_revoked({:ok, %Flame.SessionCookie{} = token}) do
    case Flame.Accounts.get_user_by_local_id(token.sub) do
      {:ok, %Flame.User{disabled: true}} ->
        {:error, :user_disabled}

      {:ok, %Flame.User{valid_since: earliest_iat}} ->
        if token.iat >= DateTime.from_unix!(earliest_iat) do
          {:ok, token}
        else
          {:error, :cookie_revoked}
        end

      {:error, :user_not_found} ->
        {:error, :user_not_found}
    end
  end

  defp do_request(method, data) do
    Flame.client()
    |> Tesla.post!("/projects/#{Flame.project()}:#{method}", data)
    |> handle_response()
  end

  defp handle_response(%{status: 400, body: %{"error" => %{"message" => message}}}) do
    reason =
      case message do
        "INVALID_ID_TOKEN" ->
          :invalid_id_token

        "TOKEN_EXPIRED" ->
          :token_expired

        "USER_NOT_FOUND" ->
          :user_not_found

        "MISSING_ID_TOKEN" ->
          :missing_id_token
      end

    {:error, reason}
  end

  defp handle_response(%{status: 200, body: body}) do
    {:ok, body}
  end
end
