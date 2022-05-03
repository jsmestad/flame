defmodule Flame.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Flame.TestCase
    end
  end

  setup _tags do
    start_supervised!(Flame.Application)
    # bypass = Bypass.open()

    # Bypass.expect(bypass, fn conn ->
    #   IO.inspect("HEY THERE 😎")
    #   body = ~s|{"access_token":"dummy","expires_in":3599,"token_type":"Bearer"}|
    #   Plug.Conn.resp(conn, 200, body)
    # end)

    :ok
  end

  setup :purge_firebase_on_exit!

  @doc """
  Clean up any items in Firebase Emulator between tests.
  """
  def purge_firebase_on_exit!(_context \\ %{}) do
    ExUnit.Callbacks.on_exit(fn ->
      Finch.start_link(name: MyFinch)

      Finch.build(
        :delete,
        "http://localhost:9099/emulator/v1/projects/#{Flame.project()}/accounts"
      )
      |> Finch.request(MyFinch)
    end)

    :ok
  end

  def build(:user, attrs) do
    attrs =
      Enum.into(attrs, %{
        display_name: "Fake Name",
        email: Faker.Internet.email(),
        email_verified: true,
        password: "secret-password"
      })

    if Map.get(attrs, :skip_firebase, false) do
      struct(Flame.User, attrs)
    else
      {:ok, user} = Flame.Accounts.create_user(attrs, attrs[:password])
      user
    end

    # struct(Flame.User, attrs)
  end
end
