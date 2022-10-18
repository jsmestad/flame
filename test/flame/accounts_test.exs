defmodule Flame.AccountsTest do
  use Flame.TestCase

  alias Flame.Accounts

  @existing_config Application.compile_env(:flame, Flame)

  setup do
    %{
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

    test "lists the providers for the user" do
      # NOTE email matches the key below
      user = build(:user, email: "yoav@cloudinary.com", password: "secret-password")

      assert Accounts.fetch_providers(user.email) == {:ok, ["password"]}
      assert {:ok, %Flame.IdToken{}} = Accounts.sign_in(user.email, "secret-password")

      %{status: 200} =
        Tesla.post!(Flame.client(), "/accounts:signInWithIdp", %{
          requestUri: "http://localhost",
          postBody:
            "id_token=eyJhbGciOiJSUzI1NiIsImtpZCI6ImNjM2Y0ZThiMmYxZDAyZjBlYTRiMWJkZGU1NWFkZDhiMDhiYzUzODYiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiWW9hdiBOaXJhbiIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS0vQU9oMTRHajczX2tnUmQxVnBTV3Y2RzRrOU41ZHZLNkRESjJlaGZrUUhPN2w9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbWVkaWEtZmxvdy1iMzdkMSIsImF1ZCI6Im1lZGlhLWZsb3ctYjM3ZDEiLCJhdXRoX3RpbWUiOjE2MjAyMTExOTMsInVzZXJfaWQiOiJFa2lhRUc0NXFoTU9Jbk5VT01IbHJOYVpuR24yIiwic3ViIjoiRWtpYUVHNDVxaE1PSW5OVU9NSGxyTmFabkduMiIsImlhdCI6MTYyMDIxMTE5MywiZXhwIjoxNjIwMjE0NzkzLCJlbWFpbCI6InlvYXZAY2xvdWRpbmFyeS5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNzEwMTUyNzU2NTgzOTU0Nzg4MyJdLCJlbWFpbCI6WyJ5b2F2QGNsb3VkaW5hcnkuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.grIXaGN9-Ue92EZqN7NNgoUo3vQF8zxApvHZ6IvucWIQOJKDMJnSxEvWGH6P7vg4ETQldgg1VtLNC-eRhE_417OJYKkqpTutsT6mihUgiAHmFoVWcrcgDFn0PSi0eznqFiYq36OpAJQo8CiaMIrFeyqrhe9qQUdhKvz-1XzksbsKc1gna-6yVcdaQtcEfsmmrMJnfK9MQ1MsE2_F3ooVzV5Ym1b_6cFNAilBPHThIVn7kZ64kTBqTOUon06PV3uD_Svv3X3B971cW9oXSnZGZDEJs6fP0vHyKhakFrNVNwcgbhPnJ7WIkNjh0WuG3yYMSNn8LauZMllHP2iV3nICAA&providerId=google.com",
          returnSecureToken: true
        })

      assert Accounts.fetch_providers(user.email) == {:ok, ["password", "google.com"]}
    end

    test "lists an empty list when the user is not found" do
      user = build(:user, skip_firebase: true)
      assert Accounts.fetch_providers(user.email) == {:ok, []}
    end
  end

  describe "unlink_providers/3" do
    setup [:seed_user]

    test "unlinks the providers for the user", %{user: user} do
      assert Accounts.fetch_providers(user.email) == {:ok, ["password"]}
      assert Accounts.unlink_providers(user.local_id, ["password"]) == {:ok, []}
    end

    test "unlinks an idP provider" do
      # NOTE email matches the key below
      user = build(:user, email: "yoav@cloudinary.com", password: "secret-password")

      assert Accounts.fetch_providers(user.email) == {:ok, ["password"]}
      assert {:ok, %Flame.IdToken{}} = Accounts.sign_in(user.email, "secret-password")

      %{status: 200} =
        Tesla.post!(Flame.client(), "/accounts:signInWithIdp", %{
          requestUri: "http://localhost",
          postBody:
            "id_token=eyJhbGciOiJSUzI1NiIsImtpZCI6ImNjM2Y0ZThiMmYxZDAyZjBlYTRiMWJkZGU1NWFkZDhiMDhiYzUzODYiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiWW9hdiBOaXJhbiIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS0vQU9oMTRHajczX2tnUmQxVnBTV3Y2RzRrOU41ZHZLNkRESjJlaGZrUUhPN2w9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbWVkaWEtZmxvdy1iMzdkMSIsImF1ZCI6Im1lZGlhLWZsb3ctYjM3ZDEiLCJhdXRoX3RpbWUiOjE2MjAyMTExOTMsInVzZXJfaWQiOiJFa2lhRUc0NXFoTU9Jbk5VT01IbHJOYVpuR24yIiwic3ViIjoiRWtpYUVHNDVxaE1PSW5OVU9NSGxyTmFabkduMiIsImlhdCI6MTYyMDIxMTE5MywiZXhwIjoxNjIwMjE0NzkzLCJlbWFpbCI6InlvYXZAY2xvdWRpbmFyeS5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNzEwMTUyNzU2NTgzOTU0Nzg4MyJdLCJlbWFpbCI6WyJ5b2F2QGNsb3VkaW5hcnkuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.grIXaGN9-Ue92EZqN7NNgoUo3vQF8zxApvHZ6IvucWIQOJKDMJnSxEvWGH6P7vg4ETQldgg1VtLNC-eRhE_417OJYKkqpTutsT6mihUgiAHmFoVWcrcgDFn0PSi0eznqFiYq36OpAJQo8CiaMIrFeyqrhe9qQUdhKvz-1XzksbsKc1gna-6yVcdaQtcEfsmmrMJnfK9MQ1MsE2_F3ooVzV5Ym1b_6cFNAilBPHThIVn7kZ64kTBqTOUon06PV3uD_Svv3X3B971cW9oXSnZGZDEJs6fP0vHyKhakFrNVNwcgbhPnJ7WIkNjh0WuG3yYMSNn8LauZMllHP2iV3nICAA&providerId=google.com",
          returnSecureToken: true
        })

      assert Accounts.unlink_providers(user.local_id, ["google.com"]) ==
               {:ok, ["password"]}
    end

    test "removing a provider that does not exist", %{user: user} do
      assert Accounts.unlink_providers(user.local_id, ["google.com"]) ==
               {:ok, ["password"]}
    end

    test "errors when user is unknown" do
      assert Accounts.unlink_providers("unknown", ["google.com"]) ==
               {:error, :user_not_found}
    end
  end

  describe "create_user/3" do
    test "creates a user" do
      user = build(:user, skip_firebase: true)

      assert {:ok, %{local_id: _}} = Accounts.create_user(user, "secret")
    end

    test "fails when user email is duplicated" do
      user = build(:user, skip_firebase: true)
      {:ok, _} = Accounts.create_user(user, "secret")

      assert Accounts.create_user(user, "secret") == {:error, :email_exists}
    end
  end

  describe "sign_in/3" do
    setup [:seed_user]

    test "returns a secure token", %{user: user, password: password} do
      expected_id = user.local_id

      assert {:ok, %Flame.IdToken{value: _, sub: ^expected_id}} =
               Accounts.sign_in(user.email, password)
    end

    test "returns error with incorrect password", %{user: user} do
      assert Accounts.sign_in(user.email, "bad-password") ==
               {:error, :invalid_credentials}
    end

    test "returns error with unknown user login" do
      assert Accounts.sign_in("foo", "bar") == {:error, :invalid_credentials}
    end
  end

  describe "get_user/2" do
    setup [:seed_user]

    # NOTE: this test does not work against Flame Emulator
    # test "returns the user when there is a match", %{user: user, client:  password: pw} do
    #   {:ok, token, _} = Accounts.sign_in( user.email, pw)
    #   assert {:ok, _} = Accounts.find_user_by_email( user.email)
    #   assert {:ok, result} = Accounts.get_user( token)
    #   assert result["localId"] == user.local_id
    # end

    test "returns error when there is more than one match" do
      bypass = Bypass.open(port: 3000)

      Application.put_env(
        :flame,
        Flame,
        Keyword.put(@existing_config, :client, {Flame.Client, :new, ["http://localhost:3000"]})
      )

      data = %{users: [user_fixture(), user_fixture()]}
      mock_response(bypass, "lookup", data, 200)

      assert_raise CaseClauseError, fn -> Accounts.get_user("myIdpToken") end
    after
      Application.put_env(:flame, Flame, @existing_config)
    end

    test "returns error when the token is invalid" do
      assert Accounts.get_user("invalid_token") ==
               {:error, :user_not_found}
    end
  end

  describe "find_user_by_email/2" do
    setup [:seed_user]

    test "returns the user when there is a match", %{user: user} do
      assert {:ok, %Flame.User{} = result} = Accounts.find_user_by_email(user.email)
      assert result.local_id == user.local_id
    end

    test "throws error when there is more than one match" do
      bypass = Bypass.open(port: 3000)

      Application.put_env(
        :flame,
        Flame,
        Keyword.put(@existing_config, :client, {Flame.Client, :new, ["http://localhost:3000"]})
      )

      data = %{users: [user_fixture(), user_fixture()]}
      mock_response(bypass, "lookup", data, 200)

      assert Accounts.find_user_by_email("multiple-matches@example.com") ==
               {:error, :multiple_matches}
    after
      Application.put_env(:flame, Flame, @existing_config)
    end

    test "returns error when no user matches" do
      assert Accounts.find_user_by_email("missing-user@example.com") ==
               {:error, :user_not_found}
    end
  end

  describe "get_user_by_local_id/2" do
    setup [:seed_user]

    test "returns the user when there is a match", %{user: user} do
      assert {:ok, %Flame.User{} = result} = Accounts.get_user_by_local_id(user.local_id)
      assert result.local_id == user.local_id
    end

    test "throws error when there is more than one match" do
      bypass = Bypass.open(port: 3000)

      Application.put_env(
        :flame,
        Flame,
        Keyword.put(@existing_config, :client, {Flame.Client, :new, ["http://localhost:3000"]})
      )

      data = %{users: [user_fixture(), user_fixture()]}
      mock_response(bypass, "lookup", data, 200)

      assert_raise CaseClauseError, fn ->
        Accounts.get_user_by_local_id("multi")
      end
    after
      Application.put_env(:flame, Flame, @existing_config)
    end

    test "returns error when no user matches" do
      assert Accounts.get_user_by_local_id("unknown-id") ==
               {:error, :user_not_found}
    end
  end

  describe "update_user/2" do
    setup [:seed_user]

    test "updates the users name", %{user: user} do
      assert {:ok, user} = Accounts.update_user(%{user | display_name: "Updated name"})
      assert user.display_name == "Updated name"
    end

    test "fails when user is missing" do
      user = build(:user, skip_firebase: true, local_id: "unknown")
      assert {:error, :user_not_found} == Accounts.update_user(user)
    end
  end

  describe "update_user_password/3" do
    setup [:seed_user]

    test "updates the users password", %{user: user} do
      assert Accounts.sign_in(user.email, "new-password") ==
               {:error, :invalid_credentials}

      assert {:ok, %Flame.User{}} = Accounts.update_user_password(user.local_id, "new-password")

      assert {:ok, %Flame.IdToken{}} = Accounts.sign_in(user.email, "new-password")
    end

    test "fails when user is missing" do
      user = build(:user, skip_firebase: true, local_id: "unknown")

      assert Accounts.update_user_password(user.local_id, "new-password") ==
               {:error, :user_not_found}
    end
  end

  describe "delete_user/2" do
    setup [:seed_user]

    test "successfully removes the user", %{user: user} do
      assert {:ok, %{local_id: nil}} = Accounts.delete_user(user.local_id)
    end

    test "fails to delete a missing user" do
      user = build(:user, skip_firebase: true, local_id: "a9999")
      assert Accounts.delete_user(user.local_id) == {:error, :user_not_found}
    end
  end

  describe "send_password_reset/2" do
    setup [:seed_user]

    test "sends a password reset email", %{user: user} do
      assert Accounts.send_password_reset(user.email) == :ok
    end

    test "fails when email is missing" do
      assert Accounts.send_password_reset("missing-user@example.com") ==
               {:error, :email_not_found}
    end
  end

  describe "confirm_password_reset/3" do
    setup [:seed_user]

    test "sends a password reset email" do
      bypass = Bypass.open(port: 3000)

      Application.put_env(
        :flame,
        Flame,
        Keyword.put(@existing_config, :client, {Flame.Client, :new, ["http://localhost:3000"]})
      )

      mock_response(
        bypass,
        "sendOobCode",
        %{
          "email" => "[user@example.com]",
          "requestType" => "PASSWORD_RESET"
        },
        200
      )

      assert Accounts.confirm_password_reset("correctCode", "newPassword") == :ok
    after
      Application.put_env(:flame, Flame, @existing_config)
    end

    test "fails when expired code is used" do
      bypass = Bypass.open(port: 3000)

      Application.put_env(
        :flame,
        Flame,
        Keyword.put(@existing_config, :client, {Flame.Client, :new, ["http://localhost:3000"]})
      )

      mock_response(
        bypass,
        "sendOobCode",
        %{"error" => %{"message" => "EXPIRED_OOB_CODE"}},
        400
      )

      assert Accounts.confirm_password_reset("wrongCode", "newPassword") ==
               {:error, :expired_oob_code}
    after
      Application.put_env(:flame, Flame, @existing_config)
    end

    test "fails when invalid code is used" do
      assert Accounts.confirm_password_reset("wrongCode", "newPassword") ==
               {:error, :invalid_oob_code}
    end
  end

  describe "send_confirmation_email/2" do
    setup [:seed_user]

    # NOTE: uses bypass instead of emulator due to 500 error
    test "sends a confirmation email", %{user: user} do
      bypass = Bypass.open(port: 3000)

      Application.put_env(
        :flame,
        Flame,
        Keyword.put(@existing_config, :client, {Flame.Client, :new, ["http://localhost:3000"]})
      )

      mock_response(
        bypass,
        "sendOobCode",
        %{
          "email" => "user@example.com"
        },
        200
      )

      assert Accounts.send_confirmation_email(user.email) == :ok
    after
      Application.put_env(:flame, Flame, @existing_config)
    end

    test "fails when user is missing" do
      bypass = Bypass.open(port: 3000)

      Application.put_env(
        :flame,
        Flame,
        Keyword.put(@existing_config, :client, {Flame.Client, :new, ["http://localhost:3000"]})
      )

      mock_response(
        bypass,
        "sendOobCode",
        %{"error" => %{"message" => "USER_NOT_FOUND"}},
        400
      )

      # user = build(:user, skip_firebase: true, local_id: "9999")

      assert Accounts.send_confirmation_email("unknown@example.com") ==
               {:error, :user_not_found}
    after
      Application.put_env(:flame, Flame, @existing_config)
    end
  end

  describe "verify_session/1" do
    test "returns a working value" do
      now = Epoch.now()

      token =
        ExFirebaseAuth.Mock.generate_token("my_user_id", %{
          "email" => "foo@bar.example",
          "iat" => now,
          "exp" => now + 10,
          "auth_time" => now - 10
        })
        |> Flame.IdToken.new!()

      assert {:ok, %Flame.IdToken{sub: "my_user_id", email: "foo@bar.example"}} =
               Accounts.verify_session(token)
    end

    test "fails on expired JWT" do
      sub = Enum.random(?a..?z)

      claims = %{
        "exp" => Epoch.now() - 5,
        "iat" => Epoch.now() - 10,
        "auth_time" => Epoch.now() - 10
      }

      valid_token =
        ExFirebaseAuth.Mock.generate_token(sub, claims)
        |> Flame.IdToken.new!()

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
            "iss" => "issuer",
            "iat" => Epoch.now(),
            "exp" => Epoch.now() + 10,
            "auth_time" => Epoch.now()
          }
        )
        |> JOSE.JWS.compact()

      token = Flame.IdToken.new!(token)
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
