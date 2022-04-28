defmodule Flame.AccountsTest do
  use Flame.TestCase

  alias Flame.Accounts

  @emulator_url "http://localhost:9099/identitytoolkit.googleapis.com/v1/"

  setup do
    %{
      client: Flame.Client.new(@emulator_url),
      password: "secret-password"
    }
  end

  defp mock_response(bypass, action, data, status_code) when is_map(data) do
    Bypass.expect_once(bypass, "POST", "/accounts:#{action}", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        status_code,
        Jason.encode!(data)
      )
    end)
  end

  describe "fetch_providers/2" do
    setup [:seed_user]

    test "lists the providers for the user", %{client: client} do
      # NOTE email matches the key below
      user = build(:user, email: "yoav@cloudinary.com", password: "secret-password")

      assert Accounts.fetch_providers(client, user.email) == {:ok, ["password"]}
      assert {:ok, _, _} = Accounts.sign_in(client, user.email, "secret-password")

      %{status: 200} =
        Tesla.post!(client, "/accounts:signInWithIdp", %{
          requestUri: "http://localhost",
          postBody:
            "id_token=eyJhbGciOiJSUzI1NiIsImtpZCI6ImNjM2Y0ZThiMmYxZDAyZjBlYTRiMWJkZGU1NWFkZDhiMDhiYzUzODYiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiWW9hdiBOaXJhbiIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS0vQU9oMTRHajczX2tnUmQxVnBTV3Y2RzRrOU41ZHZLNkRESjJlaGZrUUhPN2w9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbWVkaWEtZmxvdy1iMzdkMSIsImF1ZCI6Im1lZGlhLWZsb3ctYjM3ZDEiLCJhdXRoX3RpbWUiOjE2MjAyMTExOTMsInVzZXJfaWQiOiJFa2lhRUc0NXFoTU9Jbk5VT01IbHJOYVpuR24yIiwic3ViIjoiRWtpYUVHNDVxaE1PSW5OVU9NSGxyTmFabkduMiIsImlhdCI6MTYyMDIxMTE5MywiZXhwIjoxNjIwMjE0NzkzLCJlbWFpbCI6InlvYXZAY2xvdWRpbmFyeS5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNzEwMTUyNzU2NTgzOTU0Nzg4MyJdLCJlbWFpbCI6WyJ5b2F2QGNsb3VkaW5hcnkuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.grIXaGN9-Ue92EZqN7NNgoUo3vQF8zxApvHZ6IvucWIQOJKDMJnSxEvWGH6P7vg4ETQldgg1VtLNC-eRhE_417OJYKkqpTutsT6mihUgiAHmFoVWcrcgDFn0PSi0eznqFiYq36OpAJQo8CiaMIrFeyqrhe9qQUdhKvz-1XzksbsKc1gna-6yVcdaQtcEfsmmrMJnfK9MQ1MsE2_F3ooVzV5Ym1b_6cFNAilBPHThIVn7kZ64kTBqTOUon06PV3uD_Svv3X3B971cW9oXSnZGZDEJs6fP0vHyKhakFrNVNwcgbhPnJ7WIkNjh0WuG3yYMSNn8LauZMllHP2iV3nICAA&providerId=google.com",
          returnSecureToken: true
        })

      assert Accounts.fetch_providers(client, user.email) == {:ok, ["password", "google.com"]}
    end

    test "lists an empty list when the user is not found", %{client: client} do
      user = build(:user, skip_firebase: true)
      assert Accounts.fetch_providers(client, user.email) == {:ok, []}
    end
  end

  describe "unlink_providers/3" do
    setup [:seed_user]

    test "unlinks the providers for the user", %{client: client, user: user} do
      assert Accounts.fetch_providers(client, user.email) == {:ok, ["password"]}
      assert Accounts.unlink_providers(client, user.local_id, ["password"]) == {:ok, []}
    end

    test "unlinks an idP provider", %{client: client} do
      # NOTE email matches the key below
      user = build(:user, email: "yoav@cloudinary.com", password: "secret-password")

      assert Accounts.fetch_providers(client, user.email) == {:ok, ["password"]}
      assert {:ok, _, _} = Accounts.sign_in(client, user.email, "secret-password")

      %{status: 200} =
        Tesla.post!(client, "/accounts:signInWithIdp", %{
          requestUri: "http://localhost",
          postBody:
            "id_token=eyJhbGciOiJSUzI1NiIsImtpZCI6ImNjM2Y0ZThiMmYxZDAyZjBlYTRiMWJkZGU1NWFkZDhiMDhiYzUzODYiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiWW9hdiBOaXJhbiIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS0vQU9oMTRHajczX2tnUmQxVnBTV3Y2RzRrOU41ZHZLNkRESjJlaGZrUUhPN2w9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbWVkaWEtZmxvdy1iMzdkMSIsImF1ZCI6Im1lZGlhLWZsb3ctYjM3ZDEiLCJhdXRoX3RpbWUiOjE2MjAyMTExOTMsInVzZXJfaWQiOiJFa2lhRUc0NXFoTU9Jbk5VT01IbHJOYVpuR24yIiwic3ViIjoiRWtpYUVHNDVxaE1PSW5OVU9NSGxyTmFabkduMiIsImlhdCI6MTYyMDIxMTE5MywiZXhwIjoxNjIwMjE0NzkzLCJlbWFpbCI6InlvYXZAY2xvdWRpbmFyeS5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNzEwMTUyNzU2NTgzOTU0Nzg4MyJdLCJlbWFpbCI6WyJ5b2F2QGNsb3VkaW5hcnkuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.grIXaGN9-Ue92EZqN7NNgoUo3vQF8zxApvHZ6IvucWIQOJKDMJnSxEvWGH6P7vg4ETQldgg1VtLNC-eRhE_417OJYKkqpTutsT6mihUgiAHmFoVWcrcgDFn0PSi0eznqFiYq36OpAJQo8CiaMIrFeyqrhe9qQUdhKvz-1XzksbsKc1gna-6yVcdaQtcEfsmmrMJnfK9MQ1MsE2_F3ooVzV5Ym1b_6cFNAilBPHThIVn7kZ64kTBqTOUon06PV3uD_Svv3X3B971cW9oXSnZGZDEJs6fP0vHyKhakFrNVNwcgbhPnJ7WIkNjh0WuG3yYMSNn8LauZMllHP2iV3nICAA&providerId=google.com",
          returnSecureToken: true
        })

      assert Accounts.unlink_providers(client, user.local_id, ["google.com"]) ==
               {:ok, ["password"]}
    end

    test "removing a provider that does not exist", %{client: client, user: user} do
      assert Accounts.unlink_providers(client, user.local_id, ["google.com"]) ==
               {:ok, ["password"]}
    end

    test "errors when user is unknown", %{client: client} do
      assert Accounts.unlink_providers(client, "unknown", ["google.com"]) ==
               {:error, :user_not_found}
    end
  end

  describe "create_user/3" do
    test "creates a user", %{client: client} do
      user = build(:user, skip_firebase: true)

      assert {:ok, %{local_id: _}} = Accounts.create_user(client, user, "secret")
    end

    test "fails when user email is duplicated", %{client: client} do
      user = build(:user, skip_firebase: true)
      {:ok, _} = Accounts.create_user(client, user, "secret")

      assert Accounts.create_user(client, user, "secret") == {:error, :email_exists}
    end
  end

  describe "sign_in/3" do
    setup [:seed_user]

    test "returns a secure token", %{client: client, user: user, password: password} do
      assert {:ok, _, _} = Accounts.sign_in(client, user.email, password)
    end

    test "returns error with incorrect password", %{client: client, user: user} do
      assert Accounts.sign_in(client, user.email, "bad-password") ==
               {:error, :invalid_credentials}
    end

    test "returns error with unknown user login", %{client: client} do
      assert Accounts.sign_in(client, "foo", "bar") == {:error, :invalid_credentials}
    end
  end

  describe "get_user/2" do
    setup [:seed_user]

    # NOTE: this test does not work against Flame Emulator
    # test "returns the user when there is a match", %{user: user, client: client, password: pw} do
    #   {:ok, token, _} = Accounts.sign_in(client, user.email, pw)
    #   assert {:ok, _} = Accounts.find_user_by_email(client, user.email)
    #   assert {:ok, result} = Accounts.get_user(client, token)
    #   assert result["localId"] == user.local_id
    # end

    test "returns error when there is more than one match" do
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      data = %{users: [user_fixture(), user_fixture()]}
      mock_response(bypass, "lookup", data, 200)

      assert_raise CaseClauseError, fn -> Accounts.get_user(client, "myIdpToken") end
    end

    test "returns error when the token is invalid", %{client: client} do
      assert Accounts.get_user(client, "invalid_token") ==
               {:error, :user_not_found}
    end
  end

  describe "find_user_by_email/2" do
    setup [:seed_user]

    test "returns the user when there is a match", %{user: user, client: client} do
      assert {:ok, result} = Accounts.find_user_by_email(client, user.email)
      assert result["localId"] == user.local_id
    end

    test "throws error when there is more than one match" do
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      data = %{users: [user_fixture(), user_fixture()]}
      mock_response(bypass, "lookup", data, 200)

      assert Accounts.find_user_by_email(client, "multiple-matches@example.com") ==
               {:error, :multiple_matches}
    end

    test "returns error when no user matches", %{client: client} do
      assert Accounts.find_user_by_email(client, "missing-user@example.com") ==
               {:error, :user_not_found}
    end
  end

  describe "get_user_by_local_id/2" do
    setup [:seed_user]

    test "returns the user when there is a match", %{user: user, client: client} do
      assert {:ok, result} = Accounts.get_user_by_local_id(client, user.local_id)
      assert result["localId"] == user.local_id
    end

    test "throws error when there is more than one match" do
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      data = %{users: [user_fixture(), user_fixture()]}
      mock_response(bypass, "lookup", data, 200)

      assert_raise CaseClauseError, fn ->
        Accounts.get_user_by_local_id(client, "multi")
      end
    end

    test "returns error when no user matches", %{client: client} do
      assert Accounts.get_user_by_local_id(client, "unknown-id") ==
               {:error, :user_not_found}
    end
  end

  describe "update_user/2" do
    setup [:seed_user]

    test "updates the users name", %{client: client, user: user} do
      assert {:ok, user} = Accounts.update_user(client, %{user | display_name: "Updated name"})
      assert user.display_name == "Updated name"
    end

    test "fails when user is missing", %{client: client} do
      user = build(:user, skip_firebase: true, local_id: "unknown")
      assert {:error, :user_not_found} == Accounts.update_user(client, user)
    end
  end

  describe "update_user_password/3" do
    setup [:seed_user]

    test "updates the users password", %{client: client, user: user} do
      assert Accounts.sign_in(client, user.email, "new-password") ==
               {:error, :invalid_credentials}

      assert {:ok, %Flame.User{}} =
               Accounts.update_user_password(client, user.local_id, "new-password")

      assert {:ok, _, _} = Accounts.sign_in(client, user.email, "new-password")
    end

    test "fails when user is missing", %{client: client} do
      user = build(:user, skip_firebase: true, local_id: "unknown")

      assert Accounts.update_user_password(client, user.local_id, "new-password") ==
               {:error, :user_not_found}
    end
  end

  describe "delete_user/2" do
    setup [:seed_user]

    test "successfully removes the user", %{client: client, user: user} do
      assert {:ok, %{local_id: nil}} = Accounts.delete_user(client, user.local_id)
    end

    test "fails to delete a missing user", %{client: client} do
      user = build(:user, skip_firebase: true, local_id: "a9999")
      assert Accounts.delete_user(client, user.local_id) == {:error, :user_not_found}
    end
  end

  describe "send_password_reset/2" do
    setup [:seed_user]

    test "sends a password reset email", %{client: client, user: user} do
      assert Accounts.send_password_reset(client, user.email) == :ok
    end

    test "fails when email is missing", %{client: client} do
      assert Accounts.send_password_reset(client, "missing-user@example.com") ==
               {:error, :email_not_found}
    end
  end

  describe "confirm_password_reset/3" do
    setup [:seed_user]

    test "sends a password reset email" do
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      mock_response(
        bypass,
        "sendOobCode",
        %{
          "email" => "[user@example.com]",
          "requestType" => "PASSWORD_RESET"
        },
        200
      )

      assert Accounts.confirm_password_reset(client, "correctCode", "newPassword") == :ok
    end

    test "fails when expired code is used" do
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      mock_response(
        bypass,
        "sendOobCode",
        %{"error" => %{"message" => "EXPIRED_OOB_CODE"}},
        400
      )

      assert Accounts.confirm_password_reset(client, "wrongCode", "newPassword") ==
               {:error, :expired_oob_code}
    end

    test "fails when invalid code is used", %{client: client} do
      assert Accounts.confirm_password_reset(client, "wrongCode", "newPassword") ==
               {:error, :invalid_oob_code}
    end
  end

  describe "send_confirmation_email/2" do
    setup [:seed_user]

    # NOTE: uses bypass instead of emulator due to 500 error
    test "sends a confirmation email", %{user: user} do
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      mock_response(
        bypass,
        "sendOobCode",
        %{
          "email" => "user@example.com"
        },
        200
      )

      assert Accounts.send_confirmation_email(client, user.email) == :ok
    end

    test "fails when user is missing" do
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      mock_response(
        bypass,
        "sendOobCode",
        %{"error" => %{"message" => "USER_NOT_FOUND"}},
        400
      )

      # user = build(:user, skip_firebase: true, local_id: "9999")

      assert Accounts.send_confirmation_email(client, "unknown@example.com") ==
               {:error, :user_not_found}
    end
  end

  describe "verify_session/1" do
    test "returns a working value" do
      token = ExFirebaseAuth.Mock.generate_token("my_user_id", %{"email" => "foo@bar.example"})
      assert {:ok, "my_user_id", "foo@bar.example"} == Accounts.verify_session(token)
    end

    test "fails on expired JWT" do
      sub = Enum.random(?a..?z)

      time_in_past = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.to_unix()
      claims = %{"exp" => time_in_past}

      valid_token = ExFirebaseAuth.Mock.generate_token(sub, claims)

      assert {:error, "Expired JWT"} = Accounts.verify_session(valid_token)
    end

    test "fails on invalid signature with non-matching kid" do
      sub = Enum.random(?a..?z)
      {_invalid_kid, public_key, private_key} = ExFirebaseAuth.Mock.generate_key()

      _invalid_kid = JOSE.JWK.thumbprint(:md5, public_key)
      [{valid_kid, _}] = :ets.lookup(ExFirebaseAuth.Mock, :ets.first(ExFirebaseAuth.Mock))

      {_, token} =
        private_key
        |> JOSE.JWT.sign(
          %{
            "alg" => "RS256",
            "kid" => valid_kid
          },
          %{
            "sub" => sub,
            "iss" => "issuer"
          }
        )
        |> JOSE.JWS.compact()

      assert {:error, "Invalid signature"} = Accounts.verify_session(token)
    end
  end

  defp user_fixture do
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
  end

  defp seed_user(%{password: password}) do
    user = build(:user, password: password)

    %{user: user}
  end
end
