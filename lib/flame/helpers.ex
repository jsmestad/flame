defmodule Flame.Helpers do
  @moduledoc false

  def transform_params(params) do
    Enum.reduce(params, %{}, fn
      {"createdAt", val}, acc ->
        Map.put(acc, "created_at", String.to_integer(val))

      {"lastLoginAt", val}, acc ->
        Map.put(acc, "last_login_at", String.to_integer(val))

      {"validSince", val}, acc ->
        Map.put(acc, "valid_since", String.to_integer(val))

      {key, [_ | _] = val}, acc ->
        Map.put(acc, Macro.underscore(key), Enum.map(val, &transform_params/1))

      {key, val}, acc ->
        Map.put(acc, Macro.underscore(key), val)
    end)
  end
end
