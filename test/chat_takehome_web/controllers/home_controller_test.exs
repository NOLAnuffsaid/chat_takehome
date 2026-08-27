defmodule ChatTakehomeWeb.HomeControllerTest do
  use ChatTakehomeWeb.ConnCase, async: true

  test "redirects the root path to the home page", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert redirected_to(conn) == ~p"/home"
  end
end
