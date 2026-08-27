defmodule ChatTakehomeWeb.UserAuthTest do
  use ChatTakehomeWeb.ConnCase, async: true

  alias ChatTakehomeWeb.UserAuth

  import ChatTakehome.UsersFixtures

  test "assigns the user matching the session token", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> init_test_session(%{"session_token" => user.session_token})
      |> UserAuth.fetch_current_user([])

    assert conn.assigns.current_user == user
  end

  test "assigns nil when the session token is missing or invalid", %{conn: conn} do
    conn = init_test_session(conn, %{})

    assert UserAuth.fetch_current_user(conn, []).assigns.current_user == nil

    conn =
      conn
      |> init_test_session(%{"session_token" => "invalid-token"})
      |> UserAuth.fetch_current_user([])

    assert conn.assigns.current_user == nil
  end
end
