defmodule ChatTakehome.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ChatTakehome.Users` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        session_token: "some session_token",
        username: "some username"
      })
      |> ChatTakehome.Users.create_user()

    user
  end
end
