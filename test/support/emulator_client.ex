defmodule Flame.EmulatorClient do
  @moduledoc false

  @emulator_url "http://localhost:9099/identitytoolkit.googleapis.com/v1/"

  def new do
    Flame.Client.new(@emulator_url)
  end
end
