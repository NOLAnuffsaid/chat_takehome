defmodule ChatTakehomeWeb.UserSessionControllerTest do
  use ChatTakehomeWeb.ConnCase, async: true

  alias ChatTakehome.Users

  import ChatTakehome.UsersFixtures

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

  test "does not allow a visitor to claim an existing username", %{conn: conn} do
    username = "Ada Lovelace #{System.unique_integer([:positive])}"
    user = user_fixture(%{username: username})

    conn = post(conn, ~p"/users", user: %{username: String.downcase(username)})

    assert redirected_to(conn) == ~p"/users/new"
    assert get_session(conn, :session_token) == nil

    assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
             "That username is already in use. Choose another."

    assert Users.get_user!(user.id).username == username
  end

  test "keeps an existing verified user instead of creating another", %{conn: conn} do
    user = user_fixture()
    user_count = length(Users.list_users())
    conn = init_test_session(conn, %{"session_token" => user.session_token})

    conn = post(conn, ~p"/users", user: %{username: "another username"})

    assert redirected_to(conn) == ~p"/chat"
    assert get_session(conn, :session_token) == user.session_token
    assert length(Users.list_users()) == user_count
  end
end
