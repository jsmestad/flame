defmodule Flame.Accounts do
  @behaviour Flame.Accounts.Api

  alias Flame.User

  defmodule Api do
    @moduledoc false

    @typep user :: Flame.User.t()
    @typep pw :: String.t()
    @typep email :: String.t()
    @type code :: String.t()
    @type provider :: String.t()
    @type local_id :: String.t()
    @type id_token :: Flame.IdToken.t()
    @type raw_token :: String.t()
    @type session_cookie :: Flame.SessionCookie.t()

    @callback verify_session(id_token) :: {:ok, id_token} | {:error, reason :: String.t()}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password

    Common error codes

    EMAIL_NOT_FOUND: There is no user record corresponding to this identifier. The user may have been deleted.
    INVALID_PASSWORD: The password is invalid or the user does not have a password.
    USER_DISABLED: The user account has been disabled by an administrator.
    """
    @callback sign_in(email, pw) :: {:ok, id_token} | {:error, :invalid_credentials}

    @doc """
    https://cloud.google.com/identity-platform/docs/use-rest-api#section-verify-custom-token
    """
    @callback sign_in(local_id) :: {:ok, session_cookie} | {:error, :invalid_custom_token}

    @callback find_user_by_email(email) ::
                {:ok, user} | {:error, :user_not_found | :multiple_matches}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-create-email-password
    """
    @callback create_user(map, pw) :: {:ok, user}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-update-profile
    """
    @callback update_user(map) :: {:ok, user}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-send-password-reset-email
    """
    @callback send_password_reset(email) :: :ok | {:error, :email_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-change-password

    Common error codes

    INVALID_ID_TOKEN: The user's credential is no longer valid. The user must sign in again.
    WEAK_PASSWORD: The password must be 6 characters long or more.
    """
    @callback update_user_password(local_id, pw) ::
                {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-delete-account

    Common error codes

    USER_NOT_FOUND: There is no user record corresponding to this identifier. The user may have been deleted.
    """
    @callback delete_user(local_id) :: {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-send-email-verification

    Common error codes

    INVALID_ID_TOKEN: The user's credential is no longer valid. The user must sign in again.
    USER_NOT_FOUND: There is no user record corresponding to this identifier. The user may have been deleted.
    """
    @callback send_confirmation_email(email) :: {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-confirm-reset-password

    Common error codes

    OPERATION_NOT_ALLOWED: Password sign-in is disabled for this project.
    EXPIRED_OOB_CODE: The action code has expired.
    INVALID_OOB_CODE: The action code is invalid. This can happen if the code is malformed, expired, or has already been used.
    USER_DISABLED: The user account has been disabled by an administrator.
    """
    @callback confirm_password_reset(code, pw) ::
                :ok | {:error, :invalid_oob_code | :expired_oob_code}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-get-account-info
    """
    @callback get_user(session_cookie | id_token | raw_token) ::
                {:ok, user} | {:error, :user_not_found | :multiple_matches}

    @doc """
    https://cloud.google.com/identity-platform/docs/reference/rest/v1/accounts/lookup
    """
    @callback get_user_by_local_id(local_id) ::
                {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-fetch-providers-for-email
    """
    @callback fetch_providers(email) :: {:ok, [provider]} | {:error, :invalid_email}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-unlink-provider
    """
    @callback unlink_providers(local_id, provider | [provider]) ::
                {:ok, [provider]}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-link-with-email-password
    """
    @callback link_email_password(
                id_token | session_cookie,
                %{local_id: local_id, email: email},
                pw
              ) ::
                :ok | {:error, :invalid_id_token | :weak_password}

    @doc """
    Revoke existing tokens by setting valid_since to now.
    """
    @callback revoke_refresh_tokens(local_id) :: :ok | {:error, :user_not_found}
  end

  def create_custom_token(local_id) when is_binary(local_id) do
    now = Epoch.now()
    {:ok, email} = Flame.service_account()
    {:ok, key} = Flame.private_key()

    payload = %{
      "iss" => email,
      "sub" => email,
      "aud" =>
        "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
      "iat" => now,
      "exp" => now + 3600,
      "uid" => local_id,
      "claims" => %{}
    }

    {:ok,
     key
     |> JOSE.JWK.from_pem()
     |> JOSE.JWT.sign(%{"alg" => "RS256"}, payload)
     |> JOSE.JWS.compact()
     |> elem(1)}
  end

  @impl true
  def fetch_providers(email, continue_uri \\ "http://localhost") when is_binary(email) do
    case do_request("createAuthUri", %{
           identifier: email,
           # NOTE: continue_uri is not used. It avoids an error to supply some valid URI
           continueUri: continue_uri
         }) do
      {:ok, %{"allProviders" => providers}} ->
        {:ok, providers}
    end
  end

  @impl true
  def unlink_providers(local_id, provider_list) when is_binary(local_id) do
    case do_request("update", %{
           localId: local_id,
           deleteProvider: List.wrap(provider_list)
         }) do
      {:ok, %{"providerUserInfo" => providers}} ->
        {:ok, Enum.map(providers, &Map.get(&1, "providerId"))}

      {:error, :user_not_found} ->
        {:error, :user_not_found}
    end
  end

  @impl true
  def sign_in(local_id) when is_binary(local_id) do
    with {:ok, token} <- create_custom_token(local_id),
         {:ok, %{"isNewUser" => false, "idToken" => id_token, "refreshToken" => _}} <-
           do_request("signInWithCustomToken", %{
             token: token,
             returnSecureToken: true
           }) do
      {:ok, Flame.SessionCookie.new(id_token)}
    else
      {:error, :invalid_custom_token} -> {:error, :invalid_custom_token}
      err -> err
    end
  end

  @impl true
  def verify_session(%Flame.IdToken{} = id_token) do
    Flame.IdToken.verify(id_token)
  end

  @impl true
  def sign_in(email, password) when is_binary(email) and is_binary(password) do
    case do_request("signInWithPassword", %{
           email: email,
           password: password,
           returnSecureToken: true
         }) do
      {:ok, %{"registered" => true, "idToken" => id_token}} ->
        {:ok, Flame.IdToken.new(id_token)}

      {:error, :email_not_found} ->
        {:error, :invalid_credentials}

      {:error, :invalid_password} ->
        {:error, :invalid_credentials}
    end
  end

  @impl true
  def find_user_by_email(email) when is_binary(email) do
    case do_request("lookup", %{email: [email]}) do
      {:ok, %{"users" => [user]}} ->
        User.new(user)

      {:ok, %{"users" => [_ | _]}} ->
        {:error, :multiple_matches}

      {:ok, %{"kind" => "identitytoolkit#GetAccountInfoResponse"}} ->
        {:error, :user_not_found}
    end
  end

  @impl true
  def get_user(%Flame.IdToken{value: token}) do
    get_user(token)
  end

  def get_user(%Flame.SessionCookie{value: token}) do
    get_user(token)
  end

  def get_user(token) when is_binary(token) do
    case do_request("lookup", %{idToken: token}) do
      {:ok, %{"users" => [user]}} ->
        User.new(user)

      {:ok, %{"kind" => "identitytoolkit#GetAccountInfoResponse"}} ->
        {:error, :user_not_found}
    end
  end

  @impl true
  def get_user_by_local_id(local_id) when is_binary(local_id) do
    # NOTE: local emulator expects local_id to be a list
    case do_request("lookup", %{localId: List.wrap(local_id)}) do
      {:ok, %{"users" => [user]}} ->
        User.new(user)

      {:ok, %{"kind" => "identitytoolkit#GetAccountInfoResponse"}} ->
        {:error, :user_not_found}
    end
  end

  @impl true
  def link_email_password(%{value: id_token}, %{local_id: local_id, email: email}, password) do
    case do_request("update", %{
           idToken: id_token,
           localId: local_id,
           email: email,
           password: password,
           returnSecureToken: true
         }) do
      {:ok, _} -> :ok
      {:error, :invalid_id_token} = err -> err
      {:error, :weak_password} = err -> err
    end
  end

  @impl true
  def confirm_password_reset(code, new_password)
      when is_binary(code) and is_binary(new_password) do
    case do_request("resetPassword", %{oobCode: code, newPassword: new_password}) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def create_user(%{email: email, email_verified: verified, display_name: name}, password) do
    case do_request("signUp", %{
           email: email,
           emailVerified: verified,
           displayName: name,
           password: password
         }) do
      {:ok, params} -> User.new(params)
      {:error, _} = err -> err
    end
  end

  @impl true
  def update_user(%{
        local_id: local_id,
        display_name: name,
        email_verified: verified,
        email: email
      })
      when is_binary(local_id) do
    case do_request("update", %{
           localId: local_id,
           displayName: name,
           emailVerified: if(is_nil(verified), do: false, else: verified),
           email: email
         }) do
      {:ok, params} -> User.new(params)
      {:error, :user_not_found} -> {:error, :user_not_found}
    end
  end

  @impl true
  def revoke_refresh_tokens(local_id) when is_binary(local_id) do
    with {:ok, token} <- sign_in(local_id),
         {:ok, %{"idToken" => _id_token, "localId" => ^local_id}} <-
           do_request("update", %{
             idToken: token.value,
             localId: local_id,
             validSince: Epoch.now()
           }) do
      :ok
    else
      {:error, :user_not_found} -> {:error, :user_not_found}
    end
  end

  @impl true
  def send_confirmation_email(local_id) do
    with {:ok, id_token} <- create_custom_token(local_id),
         {:ok, _} <-
           do_request("sendOobCode", %{
             requestType: "VERIFY_EMAIL",
             idToken: id_token
           }) do
      :ok
    else
      {:error, :user_not_found} = err -> err
    end
  end

  @impl true
  def send_password_reset(email) when is_binary(email) do
    case do_request("sendOobCode", %{
           requestType: "PASSWORD_RESET",
           email: email
         }) do
      {:ok, _} -> :ok
      {:error, :email_not_found} = err -> err
    end
  end

  @impl true
  def update_user_password(local_id, password)
      when is_binary(local_id) and is_binary(password) do
    case do_request("update", %{
           password: password,
           localId: local_id
         }) do
      {:ok, params} -> User.new(params)
      {:error, :user_not_found} = err -> err
    end
  end

  @impl true
  def delete_user(local_id) when is_binary(local_id) do
    case do_request("delete", %{
           localId: local_id
         }) do
      {:ok, params} -> User.new(params)
      err -> err
    end
  end

  defp do_request(method, data) do
    Flame.client()
    |> Tesla.post!("accounts:#{method}", data)
    |> handle_response()
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp handle_response(%{status: 400, body: %{"error" => %{"message" => message}}}) do
    reason =
      case message do
        "EMAIL_EXISTS" -> :email_exists
        "EMAIL_NOT_FOUND" -> :email_not_found
        "EXPIRED_OOB_CODE" -> :expired_oob_code
        "INVALID_CUSTOM_TOKEN" -> :invalid_custom_token
        "INVALID_ID_TOKEN" -> :invalid_id_token
        "INVALID_OOB_CODE" -> :invalid_oob_code
        "INVALID_PASSWORD" -> :invalid_password
        "USER_NOT_FOUND" -> :user_not_found
        "WEAK_PASSWORD" -> :weak_password
      end

    {:error, reason}
  end

  defp handle_response(%{status: 200, body: body}) do
    {:ok, body}
  end
end
