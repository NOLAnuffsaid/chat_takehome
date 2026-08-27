defmodule ChatTakehomeWeb.ChatRoomLiveTest do
  use ChatTakehomeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ChatTakehomeWeb.Presence

  test "renders the chat route", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/chat")

    assert has_element?(view, "#chat-room")
    assert has_element?(view, "#leave-chat[href='/home']")
  end

  test "tracks the session token after connecting", %{conn: conn} do
    session_token = "session-token-#{System.unique_integer([:positive])}"
    conn = init_test_session(conn, %{"session_token" => session_token})

    {:ok, _view, _html} = live(conn, ~p"/chat")

    assert %{^session_token => %{metas: [%{}]}} = Presence.list(Presence.chat_room_topic())
  end
end
