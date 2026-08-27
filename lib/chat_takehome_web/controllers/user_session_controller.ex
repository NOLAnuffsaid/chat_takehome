defmodule ChatTakehomeWeb.UserSessionController do
  use ChatTakehomeWeb, :controller

  alias ChatTakehome.Users

  def create(conn, %{"user" => user_params}) do
    case Users.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:session_token, user.session_token)
        |> put_flash(:info, "Welcome to the chat, #{user.username}!")
        |> redirect(to: ~p"/chat")

      {:error, %Ecto.Changeset{}} ->
        conn
        |> put_flash(:error, "Please choose a valid username.")
        |> redirect(to: ~p"/users/new")
    end
  end
end
