defmodule Flame.Extensions.Goth.FinchClient do
  @moduledoc """
  Finch-based HTTP client for Goth.

  ## Options

    * `:name` - the name of the `Finch` pool to use.

    * `:default_opts` - default options that will be used on each request,
      defaults to `[]`. See `Finch.request/3` for a list of supported options.
  """

  @behaviour Goth.HTTPClient

  defstruct [:name, default_opts: []]

  @impl true
  def init(opts) do
    struct!(__MODULE__, opts)
  end

  @impl true
  def request(method, url, headers, body, opts, initial_state) do
    opts = Keyword.merge(initial_state.default_opts, opts)

    Finch.build(method, url, headers, body)
    |> Finch.request(initial_state.name, opts)
  end
end
