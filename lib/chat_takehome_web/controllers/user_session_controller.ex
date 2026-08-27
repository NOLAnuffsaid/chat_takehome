defmodule ChatTakehomeWeb.UserSessionController do
  use ChatTakehomeWeb, :controller

  alias ChatTakehome.Users
  alias ChatTakehome.Users.User

  def create(conn, %{"user" => user_params}) do
    case conn.assigns.current_user do
      %User{} ->
        redirect(conn, to: ~p"/chat")

      nil ->
        create_user(conn, user_params)
    end
  end

  defp create_user(conn, user_params) do
    case Users.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:session_token, user.session_token)
        |> put_flash(:info, "Welcome to the chat, #{user.username}!")
        |> redirect(to: ~p"/chat")

      {:error, changeset} ->
        conn
        |> put_flash(:error, join_error_message(changeset))
        |> redirect(to: ~p"/users/new")
    end
  end

  defp join_error_message(changeset) do
    case Keyword.get(changeset.errors, :username) do
      {_message, metadata} when is_list(metadata) ->
        if Keyword.get(metadata, :constraint) == :unique do
          "That username is already in use. Choose another."
        else
          "Please choose a valid username."
        end

      _other ->
        "Please choose a valid username."
    end
  end
end
