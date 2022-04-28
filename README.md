# Flame

An Elixir wrapper around the Firebase Authentication / Google Identity Platform APIs.

As of 0.1.x, Flame only creates a minimal UserRecord with Firebase. Please open a PR if you'd like to add additional parameters to the `create_user` and `update_user` requests.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flame` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flame, "~> 0.1.0"}
  ]
end
```

```elixir
config :flame, Flame,
  credentials: System.get_env("GOOGLE_APPLICATION_CREDENTIALS_JSON"),
  project: "my-project-1234",
  issuer: "https://securetoken.google.com/my-project-1234",
  cookie_issuer: "https://session.firebase.google.com/my-project-1234"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/flame>.

## Development

Getting the development environment set up can be involved as the test suite relies on [Firebase Emulator](https://firebase.google.com/docs/emulator-suite).

Contributors are welcome for improving this setup. It is not ideal by any means.

```shell
brew install firebase-cli
firebase login
firebase init # Select emulators, create new project
```

Visit [Firebase console](https://console.firebase.com) and download a copy of the service account credentials. Set the contents of that file to `GOOGLE_APPLICATION_CREDENTIALS_JSON` environment variable.

### Running tests locally

**IMPORTANT**: You need to modify `config/test.exs` to the appropriate values for your key.

You can either run `firebase emulators:exec --only auth "mix test"` OR you can run `firebase emulators:start --only auth` in your terminal, then in another window run `mix test`.
