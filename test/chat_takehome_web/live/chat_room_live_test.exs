defmodule ChatTakehomeWeb.ChatRoomLiveTest do
  use ChatTakehomeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ChatTakehome.UsersFixtures

  alias ChatTakehome.Chat
  alias ChatTakehome.Users
  alias ChatTakehomeWeb.Presence

  setup %{conn: conn} do
    user = user_fixture()

    {:ok,
     conn: init_test_session(conn, %{"session_token" => user.session_token}), current_user: user}
  end

  test "renders the chat route", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/chat")

    assert has_element?(view, "#chat-room")
    assert has_element?(view, "#leave-chat[href='/home']")
  end

  test "tracks the verified session token after connecting", %{
    conn: conn,
    current_user: current_user
  } do
    session_token = current_user.session_token

    {:ok, _view, _html} = live(conn, ~p"/chat")

    assert %{^session_token => %{metas: [%{}]}} = Presence.list(Presence.chat_room_topic())
  end

  test "redirects unauthenticated visitors to home", _context do
    conn = build_conn() |> init_test_session(%{})

    assert {:error, {:redirect, %{to: "/home"}}} = live(conn, ~p"/chat")
  end

  test "leaves and rejoins with the same verified user", %{conn: conn, current_user: user} do
    user_count = length(Users.list_users())
    {:ok, chat_view, _html} = live(conn, ~p"/chat")

    assert {:ok, home_view, _html} =
             chat_view
             |> element("#leave-chat")
             |> render_click()
             |> follow_redirect(conn, ~p"/home")

    assert has_element?(home_view, "#rejoin-chat[href='/chat']")

    assert {:ok, rejoined_chat_view, _html} =
             home_view
             |> element("#rejoin-chat")
             |> render_click()
             |> follow_redirect(conn, ~p"/chat")

    assert has_element?(rejoined_chat_view, "#chat-room")
    assert length(Users.list_users()) == user_count
    assert Users.get_user_by_session_token(user.session_token) == user
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

  test "shows persisted history to a later user session", %{conn: conn} do
    author = user_fixture()
    viewer = user_fixture()
    {:ok, message} = Chat.create_message(author, %{body: "History for future users"})
    conn = init_test_session(conn, %{"session_token" => viewer.session_token})

    {:ok, view, _html} = live(conn, ~p"/chat")

    assert has_element?(view, "#messages-#{message.id}")
  end

  test "updates the online-user list as another user joins and leaves", %{conn: conn} do
    current_user = user_fixture()
    joining_user = user_fixture()
    conn = init_test_session(conn, %{"session_token" => current_user.session_token})

    {:ok, view, _html} = live(conn, ~p"/chat")
    :ok = Phoenix.PubSub.subscribe(ChatTakehome.PubSub, Presence.chat_room_topic())

    assert {:ok, _ref} =
             Presence.track(
               self(),
               Presence.chat_room_topic(),
               joining_user.session_token,
               %{}
             )

    assert_receive %Phoenix.Socket.Broadcast{event: "presence_diff"}
    _ = :sys.get_state(view.pid)
    assert has_element?(view, "#online-user-#{joining_user.id}", joining_user.username)

    assert :ok = Presence.untrack(self(), Presence.chat_room_topic(), joining_user.session_token)

    assert_receive %Phoenix.Socket.Broadcast{event: "presence_diff"}
    _ = :sys.get_state(view.pid)
    refute has_element?(view, "#online-user-#{joining_user.id}")
  end
end
