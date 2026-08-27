defmodule ChatTakehomeWeb.UserAuth do
  use ChatTakehomeWeb, :verified_routes

  import Plug.Conn, only: [assign: 3, get_session: 2]
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias ChatTakehome.Users

  def fetch_current_user(conn, _opts) do
    assign(conn, :current_user, current_user(get_session(conn, :session_token)))
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont,
     Phoenix.Component.assign(socket, :current_user, current_user(session["session_token"]))}
  end

  def on_mount(:ensure_authenticated, _params, _session, socket) do
    case socket.assigns[:current_user] do
      nil ->
        {:halt,
         socket
         |> put_flash(:error, "Join the chat before entering the room.")
         |> redirect(to: ~p"/home")}

      _user ->
        {:cont, socket}
    end
  end

  defp current_user(session_token) do
    Users.get_user_by_session_token(session_token)
  end
end
