defmodule Flame.Accounts do
  @behaviour Flame.Accounts.Api

  alias Flame.User

  defmodule Api do
    @moduledoc false

    @typep client :: Tesla.Client.t()
    @typep user :: Flame.User.t()
    @typep pw :: String.t()
    @typep email :: String.t()
    @type token :: String.t()
    @type code :: String.t()
    @type provider :: String.t()
    @type local_id :: String.t()

    @callback verify_session(token) :: {:ok, String.t(), String.t()} | {:error, String.t()}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password

    Common error codes

    EMAIL_NOT_FOUND: There is no user record corresponding to this identifier. The user may have been deleted.
    INVALID_PASSWORD: The password is invalid or the user does not have a password.
    USER_DISABLED: The user account has been disabled by an administrator.
    """
    @callback sign_in(client, email, pw) ::
                {:ok, token, local_id} | {:error, :invalid_credentials}

    @doc """
    https://cloud.google.com/identity-platform/docs/use-rest-api#section-verify-custom-token
    """
    @callback sign_in(client, local_id) ::
                {:ok, token, local_id} | {:error, :invalid_custom_token}

    @callback find_user_by_email(client, email) ::
                {:ok, user} | {:error, :user_not_found | :multiple_matches}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-create-email-password
    """
    @callback create_user(client, map, pw) :: {:ok, user}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-update-profile
    """
    @callback update_user(client, map) :: {:ok, user}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-send-password-reset-email
    """
    @callback send_password_reset(client, email) :: :ok | {:error, :email_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-change-password

    Common error codes

    INVALID_ID_TOKEN: The user's credential is no longer valid. The user must sign in again.
    WEAK_PASSWORD: The password must be 6 characters long or more.
    """
    @callback update_user_password(client, local_id, pw) ::
                {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-delete-account

    Common error codes

    USER_NOT_FOUND: There is no user record corresponding to this identifier. The user may have been deleted.
    """
    @callback delete_user(client, local_id) :: {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-send-email-verification

    Common error codes

    INVALID_ID_TOKEN: The user's credential is no longer valid. The user must sign in again.
    USER_NOT_FOUND: There is no user record corresponding to this identifier. The user may have been deleted.
    """
    @callback send_confirmation_email(client, email) :: {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-confirm-reset-password

    Common error codes

    OPERATION_NOT_ALLOWED: Password sign-in is disabled for this project.
    EXPIRED_OOB_CODE: The action code has expired.
    INVALID_OOB_CODE: The action code is invalid. This can happen if the code is malformed, expired, or has already been used.
    USER_DISABLED: The user account has been disabled by an administrator.
    """
    @callback confirm_password_reset(client, code, pw) ::
                :ok | {:error, :invalid_oob_code | :expired_oob_code}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-get-account-info
    """
    @callback get_user(client, token) ::
                {:ok, user} | {:error, :user_not_found | :multiple_matches}

    @doc """
    https://cloud.google.com/identity-platform/docs/reference/rest/v1/accounts/lookup
    """
    @callback get_user_by_local_id(client, local_id) ::
                {:ok, user} | {:error, :user_not_found}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-fetch-providers-for-email
    """
    @callback fetch_providers(client, email) :: {:ok, [provider]} | {:error, :invalid_email}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-unlink-provider
    """
    @callback unlink_providers(client, local_id, provider | [provider]) ::
                {:ok, [provider]}

    @doc """
    https://firebase.google.com/docs/reference/rest/auth#section-link-with-email-password
    """
    @callback link_email_password(client, token, %{local_id: local_id, email: email}, pw) ::
                :ok | {:error, :invalid_id_token | :weak_password}

    @doc """
    Revoke existing tokens by setting valid_since to now.
    """
    @callback revoke_refresh_tokens(client, local_id) :: :ok | {:error, :user_not_found}
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
  def fetch_providers(client, email, continue_uri \\ "https://localhost") when is_binary(email) do
    case do_request(client, "createAuthUri", %{
           identifier: email,
           # NOTE: continue_uri is not used. It avoids an error to supply some valid URI
           continueUri: continue_uri
         }) do
      {:ok, %{"allProviders" => providers}} ->
        {:ok, providers}
    end
  end

  @impl true
  def unlink_providers(client, local_id, provider_list) when is_binary(local_id) do
    case do_request(client, "update", %{
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
  def sign_in(client, local_id) when is_binary(local_id) do
    with {:ok, token} <- create_custom_token(local_id),
         {:ok, %{"isNewUser" => false, "idToken" => id_token, "refreshToken" => _}} <-
           do_request(client, "signInWithCustomToken", %{
             token: token,
             returnSecureToken: true
           }) do
      {:ok, id_token, local_id}
    else
      {:error, :invalid_custom_token} ->
        {:error, :invalid_custom_token}

      err ->
        err
    end
  end

  @impl true
  def verify_session(token) when is_binary(token) do
    case ExFirebaseAuth.Token.verify_token(token) do
      {:ok, user_id, %{fields: %{"email" => email}}} ->
        {:ok, user_id, email}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def sign_in(client, email, password) when is_binary(email) and is_binary(password) do
    case do_request(client, "signInWithPassword", %{
           email: email,
           password: password,
           returnSecureToken: true
         }) do
      {:ok,
       %{"registered" => true, "idToken" => id_token, "refreshToken" => _, "localId" => local_id}} ->
        {:ok, id_token, local_id}

      {:error, :email_not_found} ->
        {:error, :invalid_credentials}

      {:error, :invalid_password} ->
        {:error, :invalid_credentials}
    end
  end

  @impl true
  def find_user_by_email(client, email) when is_binary(email) do
    case do_request(client, "lookup", %{email: [email]}) do
      {:ok, %{"users" => [user]}} ->
        User.new(user)

      {:ok, %{"users" => [_ | _]}} ->
        {:error, :multiple_matches}

      {:ok, %{"kind" => "identitytoolkit#GetAccountInfoResponse"}} ->
        {:error, :user_not_found}
    end
  end

  @impl true
  def get_user(client, token) when is_binary(token) do
    case do_request(client, "lookup", %{idToken: token}) do
      {:ok, %{"users" => [user]}} ->
        User.new(user)

      {:ok, %{"kind" => "identitytoolkit#GetAccountInfoResponse"}} ->
        {:error, :user_not_found}
    end
  end

  @impl true
  def get_user_by_local_id(client, local_id) when is_binary(local_id) do
    # NOTE: local emulator expects local_id to be a list
    case do_request(client, "lookup", %{localId: List.wrap(local_id)}) do
      {:ok, %{"users" => [user]}} ->
        User.new(user)

      {:ok, %{"kind" => "identitytoolkit#GetAccountInfoResponse"}} ->
        {:error, :user_not_found}
    end
  end

  @impl true
  def link_email_password(client, id_token, %{local_id: local_id, email: email}, password) do
    case do_request(client, "update", %{
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
  def confirm_password_reset(client, code, new_password)
      when is_binary(code) and is_binary(new_password) do
    case do_request(client, "resetPassword", %{oobCode: code, newPassword: new_password}) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @impl true
  def create_user(client, %{email: email, email_verified: verified, display_name: name}, password) do
    case do_request(client, "signUp", %{
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
  def update_user(client, %{
        local_id: local_id,
        display_name: name,
        email_verified: verified,
        email: email
      })
      when is_binary(local_id) do
    case do_request(client, "update", %{
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
  def revoke_refresh_tokens(client, local_id) when is_binary(local_id) do
    with {:ok, token, _} <- sign_in(client, local_id),
         {:ok, %{"idToken" => _id_token, "localId" => ^local_id}} <-
           do_request(client, "update", %{
             idToken: token,
             localId: local_id,
             validSince: Epoch.now()
           }) do
      :ok
    else
      {:error, :user_not_found} -> {:error, :user_not_found}
    end
  end

  @impl true
  def send_confirmation_email(client, local_id) do
    with {:ok, id_token} <- create_custom_token(local_id),
         {:ok, _} <-
           do_request(client, "sendOobCode", %{
             requestType: "VERIFY_EMAIL",
             idToken: id_token
           }) do
      :ok
    else
      {:error, :user_not_found} = err -> err
    end
  end

  @impl true
  def send_password_reset(client, email) when is_binary(email) do
    case do_request(client, "sendOobCode", %{
           requestType: "PASSWORD_RESET",
           email: email
         }) do
      {:ok, _} -> :ok
      {:error, :email_not_found} = err -> err
    end
  end

  @impl true
  def update_user_password(client, local_id, password)
      when is_binary(local_id) and is_binary(password) do
    case do_request(client, "update", %{
           password: password,
           localId: local_id
         }) do
      {:ok, params} -> User.new(params)
      {:error, :user_not_found} = err -> err
    end
  end

  @impl true
  def delete_user(client, local_id) when is_binary(local_id) do
    case do_request(client, "delete", %{
           localId: local_id
         }) do
      {:ok, params} -> User.new(params)
      err -> err
    end
  end

  defp do_request(client, method, data) do
    client
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
