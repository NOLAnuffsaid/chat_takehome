defmodule ChatTakehomeWeb.ChatRoomLiveTest do
  use ChatTakehomeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ChatTakehome.UsersFixtures

  alias ChatTakehome.Chat
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

  test "renders saved messages", %{conn: conn} do
    user = user_fixture()
    {:ok, message} = Chat.create_message(user, %{body: "A saved message"})

    {:ok, view, _html} = live(conn, ~p"/chat")

    assert has_element?(view, "#messages-#{message.id}")
  end

  test "streams incoming messages", %{conn: conn} do
    user = user_fixture()
    {:ok, view, _html} = live(conn, ~p"/chat")
    {:ok, message} = Chat.create_message(user, %{body: "A live message"})

    Phoenix.PubSub.broadcast(
      ChatTakehome.PubSub,
      Presence.chat_room_topic(),
      {:message_created, message}
    )

    _ = :sys.get_state(view.pid)
    assert has_element?(view, "#messages-#{message.id}")
  end
end
