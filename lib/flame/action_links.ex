defmodule Flame.ActionLinks do
  @moduledoc """
  https://firebase.google.com/docs/auth/admin/email-action-links
  """

  @type url :: String.t()
  @type email :: String.t()
  @type local_id :: String.t()

  @spec get_confirmation_link(local_id, url) :: {:ok, url} | {:error, :user_not_found}
  def get_confirmation_link(local_id, complete_url)
      when is_binary(local_id) and is_binary(complete_url) do
    with {:ok, id_token} <- Flame.Accounts.create_custom_token(local_id),
         {:ok, %{"oobLink" => link}} <-
           do_request(%{
             requestType: "VERIFY_EMAIL",
             continueUrl: complete_url,
             idToken: id_token,
             returnOobLink: true
           }) do
      {:ok, link}
    else
      {:error, :user_not_found} = err -> err
    end
  end

  @spec get_password_reset_link(email, url) :: {:ok, url} | {:error, :user_not_found}
  def get_password_reset_link(email, complete_url)
      when is_binary(email) and is_binary(complete_url) do
    case do_request(%{
           continueUrl: complete_url,
           requestType: "PASSWORD_RESET",
           email: email,
           returnOobLink: true
         }) do
      {:ok, %{"oobLink" => link}} -> {:ok, link}
      {:error, :email_not_found} = err -> err
    end
  end

  @doc """
  https://firebase.google.com/docs/auth/web/email-link-auth
  """
  @spec get_email_signin_link(email, url) :: {:ok, url} | {:error, :user_not_found}
  def get_email_signin_link(email, complete_url)
      when is_binary(email) and is_binary(complete_url) do
    case do_request(%{
           continueUrl: complete_url,
           requestType: "EMAIL_SIGNIN",
           email: email,
           returnOobLink: true
         }) do
      {:ok, %{"oobLink" => link}} -> {:ok, link}
      {:error, :email_not_found} = err -> err
    end
  end

  defp do_request(data) do
    Flame.client()
    |> Tesla.post!("accounts:sendOobCode", data)
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
