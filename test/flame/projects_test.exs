defmodule Flame.ProjectsTest do
  use Flame.TestCase

  alias Flame.Projects

  @emulator_url "http://localhost:9099/identitytoolkit.googleapis.com/v1/"
  @duration 60 * 60 * 24 * 7

  setup do
    %{
      client: Flame.Client.new(@emulator_url),
      password: "secret-password"
    }
  end

  setup [:seed_user]

  describe "create_session_cookie/3" do
    test "fails when duration is under 5 minutes", %{client: client} do
      almost_5m = 60 * 5 - 1

      assert Projects.create_session_cookie(client, "", almost_5m) ==
               {:error, :duration_too_short}
    end

    test "fails when duration is over 14 days", %{client: client} do
      over_14d = 60 * 60 * 24 * 14 + 1

      assert Projects.create_session_cookie(client, "", over_14d) ==
               {:error, :duration_too_long}
    end

    test "exchanges id token for a cookie session", %{client: client, user: user} do
      {:ok, token, _} = Flame.Accounts.sign_in(client, user.local_id)

      assert {:ok, _} = Projects.create_session_cookie(client, token, @duration)
    end
  end

  describe "verify_session/1" do
    test "passes when token itself is valid" do
      mock_cookie =
        ExFirebaseAuth.Mock.generate_cookie("user_id", %{"email" => "foo@example.com"})

      assert {:ok, "user_id", "foo@example.com"} = Projects.verify_session(mock_cookie)
    end

    test "fails on expired tokens" do
      mock_cookie =
        ExFirebaseAuth.Mock.generate_cookie("user_id", %{"email" => "foo@example.com", "exp" => 1})

      assert Projects.verify_session(mock_cookie) == {:error, "Expired JWT"}
    end
  end

  describe "verify_session/2" do
    test "passes when cookie has not been revoked" do
      cookie =
        ExFirebaseAuth.Mock.generate_cookie("user_id", %{
          "email" => "foo@example.com",
          "iat" => Epoch.now(),
          "exp" => Epoch.now() + 10
        })

      # NOTE kid is missing in emulator, so using bypass
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      data = %{users: [user_fixture()]}
      mock_response(bypass, "lookup", data, 200)

      assert {:ok, _, _} = Projects.verify_session(cookie, client)
    end

    test "fails when validSince is after iat of cookie" do
      now = Epoch.now()

      cookie =
        ExFirebaseAuth.Mock.generate_cookie("user_id", %{
          "email" => "foo@example.com",
          "iat" => now,
          "exp" => now + 10
        })

      # NOTE kid is missing in emulator, so using bypass
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      data = %{users: [user_fixture(%{"validSince" => to_string(now + 1)})]}
      mock_response(bypass, "lookup", data, 200)

      assert Projects.verify_session(cookie, client) == {:error, :cookie_revoked}
    end

    test "fails on expired tokens", %{client: client} do
      mock_cookie =
        ExFirebaseAuth.Mock.generate_cookie("user_id", %{"email" => "foo@example.com", "exp" => 1})

      assert Projects.verify_session(mock_cookie, client) == {:error, "Expired JWT"}
    end

    test "fails when user is disabled" do
      now = Epoch.now()

      cookie =
        ExFirebaseAuth.Mock.generate_cookie("user_id", %{
          "email" => "foo@example.com",
          "iat" => now,
          "exp" => now + 10
        })

      # NOTE kid is missing in emulator, so using bypass
      bypass = Bypass.open(port: 3000)
      client = Flame.Client.new("http://localhost:3000")

      data = %{users: [user_fixture(%{"disabled" => true})]}
      mock_response(bypass, "lookup", data, 200)

      assert Projects.verify_session(cookie, client) == {:error, :user_disabled}
    end

    test "fails when user is unknown", %{client: client} do
      mock_cookie =
        ExFirebaseAuth.Mock.generate_cookie("user_id", %{
          "email" => "foo@example.com",
          "iat" => Epoch.now()
        })

      assert Projects.verify_session(mock_cookie, client) == {:error, :user_not_found}
    end
  end

  defp seed_user(%{password: password}) do
    user = build(:user, password: password)

    %{user: user}
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

  defp user_fixture(attrs \\ %{}) do
    Enum.into(attrs, %{
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
    })
  end
end
