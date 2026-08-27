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

  test "sends a persisted message to other connected clients", %{conn: conn} do
    sender = user_fixture()
    recipient = user_fixture()
    body = "Live message #{System.unique_integer([:positive])}"

    sender_conn = init_test_session(conn, %{"session_token" => sender.session_token})

    recipient_conn =
      init_test_session(build_conn(), %{"session_token" => recipient.session_token})

    {:ok, sender_view, _html} = live(sender_conn, ~p"/chat")
    {:ok, recipient_view, _html} = live(recipient_conn, ~p"/chat")

    assert has_element?(sender_view, "#message-form")

    sender_view
    |> form("#message-form", message: %{body: body})
    |> render_submit()

    _ = :sys.get_state(recipient_view.pid)
    message = Enum.find(Chat.list_messages(), &(&1.body == body))

    assert message.user == sender
    assert has_element?(recipient_view, "#messages-#{message.id}")
  end

  test "lists the connected user as online", %{conn: conn} do
    user = user_fixture()
    conn = init_test_session(conn, %{"session_token" => user.session_token})

    {:ok, view, _html} = live(conn, ~p"/chat")

    assert has_element?(view, "#online-user-#{user.id}", user.username)
  end
end
