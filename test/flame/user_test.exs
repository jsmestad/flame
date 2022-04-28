defmodule Flame.UserTest do
  use Flame.TestCase

  alias Flame.ProviderInfo
  alias Flame.User

  test "new/1 converts map to camel case" do
    assert User.new(user_info_response()) ==
             {:ok,
              %User{
                created_at: 1_484_124_142_000,
                custom_auth: false,
                disabled: false,
                display_name: "John Doe",
                email: "user@example.com",
                email_verified: false,
                last_login_at: 1_484_628_946_000,
                local_id: "ZY1rJK0...",
                password_hash: "...",
                password_updated_at: 1.484_124_177e12,
                photo_url: "https://lh5.googleusercontent.com/.../photo.jpg",
                provider_user_info: [
                  %ProviderInfo{
                    display_name: "John Doe",
                    email: "user@example.com",
                    federated_id: "user@example.com",
                    photo_url: "http://localhost:8080/img1234567890/photo.png",
                    provider_id: "password",
                    raw_id: "user@example.com",
                    screen_name: "user@example.com"
                  }
                ],
                valid_since: 1_484_124_177
              }}
  end

  defp user_info_response do
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
end
