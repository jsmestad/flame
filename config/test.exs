import Config

# config :goth,
#   json: "test/support/data/test-credentials.json" |> Path.expand() |> File.read!()

config :flame, Flame,
  credentials: System.fetch_env!("GOOGLE_APPLICATION_CREDENTIALS_JSON"),
  project: "flame-test-project",
  base_url: "http://localhost:9099/identitytoolkit.googleapis.com/v1/",
  issuer: "https://securetoken.google.com/flame-test-project",
  cookie_issuer: "https://session.firebase.google.com/flame-test-project"

config :ex_firebase_auth, :mock, enabled: true

config :logger, :console, level: :error
