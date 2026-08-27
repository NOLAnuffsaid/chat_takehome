defmodule ChatTakehomeWeb.UserAuth do
  use ChatTakehomeWeb, :verified_routes

  import Plug.Conn, only: [assign: 3, delete_session: 2, get_session: 2]
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias ChatTakehome.Users

  def init(options), do: options

  def call(conn, :fetch_current_user), do: fetch_current_user(conn, [])

  def fetch_current_user(conn, _opts) do
    session_token = get_session(conn, :session_token)

    case current_user(session_token) do
      nil ->
        conn
        |> clear_stale_session_token(session_token)
        |> assign(:current_user, nil)

      user ->
        assign(conn, :current_user, user)
    end
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

  def on_mount(:redirect_if_authenticated, _params, _session, socket) do
    case socket.assigns[:current_user] do
      nil ->
        {:cont, socket}

      _user ->
        {:halt, redirect(socket, to: ~p"/chat")}
    end
  end

  defp current_user(session_token) do
    Users.get_user_by_session_token(session_token)
  end

  defp clear_stale_session_token(conn, nil), do: conn
  defp clear_stale_session_token(conn, _session_token), do: delete_session(conn, :session_token)
end
