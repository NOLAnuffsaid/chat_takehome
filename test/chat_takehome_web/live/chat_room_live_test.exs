defmodule ChatTakehomeWeb.ChatRoomLiveTest do
  use ChatTakehomeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the chat route", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/chat")

    assert has_element?(view, "#chat-room")
  end
end
