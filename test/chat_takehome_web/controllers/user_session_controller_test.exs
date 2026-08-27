defmodule ChatTakehomeWeb.UserSessionControllerTest do
  use ChatTakehomeWeb.ConnCase, async: true

  alias ChatTakehome.Users

  test "creates a user and stores its session token", %{conn: conn} do
    username = "Ada Lovelace #{System.unique_integer([:positive])}"
    conn = post(conn, ~p"/users", user: %{username: username})

    assert redirected_to(conn) == ~p"/chat"
    assert get_session(conn, :session_token)

    user = Enum.find(Users.list_users(), &(&1.username == username))
    assert get_session(conn, :session_token) == user.session_token
  end

  test "returns to the join form when the username is invalid", %{conn: conn} do
    conn = post(conn, ~p"/users", user: %{username: ""})

    assert redirected_to(conn) == ~p"/users/new"
    assert get_session(conn, :session_token) == nil
  end
end
