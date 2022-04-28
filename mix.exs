defmodule Flame.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :flame,
      package: package(),
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: [
        main: "Flame",
        extras: ["README.md", "CHANGELOG.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:epoch, "~> 1.2"},
      {:goth, ">= 1.3.0-rc.3"},
      {:finch, "~> 0.11"},
      {:tesla, "~> 1.4"},
      {:ex_firebase_auth, "~> 0.6.0",
       git: "https://github.com/jsmestad/ExFirebaseAuth.git", branch: "cookie-verification"},
      {:ecto, "~> 3.8"},
      {:jason, "~> 1.3"},

      # Types
      {:dialyxir, ">= 1.0.0", only: [:dev, :test], runtime: false},

      # Testing
      {:bypass, "~> 2.1.0-rc.0", only: :test},
      {:faker, "~> 0.13", only: [:test]},

      # Documentation
      {:ex_doc, "~> 0.28", only: :dev},

      # Lint
      {:mix_audit, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    An Elixir wrapper around the Firebase Authentication / Google Identity Platform APIs.
    """
  end

  defp package do
    [
      maintainers: ["Justin Smestad"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jsmestad/flame"}
    ]
  end
end
