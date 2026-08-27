defmodule ChatTakehomeWeb.ChatRoomLive do
  use ChatTakehomeWeb, :live_view

  alias ChatTakehome.Chat
  alias ChatTakehome.Users
  alias ChatTakehomeWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main
        id="chat-room"
        class="mx-auto flex min-h-[calc(100vh-10rem)] max-w-5xl items-center px-4 py-10 sm:px-6 lg:px-8"
      >
        <section class="w-full overflow-hidden rounded-3xl border border-base-300 bg-base-100 shadow-xl">
          <header class="flex items-center justify-between border-b border-base-300 px-6 py-5 sm:px-8">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-2xl bg-primary text-primary-content shadow-sm">
                <.icon name="hero-chat-bubble-left-right" class="size-5" />
              </div>
              <div>
                <p class="text-sm font-medium text-base-content/60">Shared room</p>
                <h1 class="text-xl font-semibold tracking-tight">Chat</h1>
              </div>
            </div>

            <.link id="leave-chat" navigate={~p"/home"} class="btn btn-ghost btn-sm gap-2">
              <.icon name="hero-arrow-left" class="size-4" /> Leave chat
            </.link>
          </header>

          <div id="messages" class="min-h-80 space-y-4 px-6 py-8 sm:px-8" phx-update="stream">
            <div id="chat-history-empty" class="hidden py-16 text-center only:block">
              <div class="mx-auto mb-5 flex size-16 items-center justify-center rounded-full bg-primary/10 text-primary">
                <.icon name="hero-chat-bubble-oval-left-ellipsis" class="size-8" />
              </div>
              <h2 class="text-lg font-semibold">The room is ready</h2>
              <p class="mx-auto mt-2 max-w-sm text-sm leading-6 text-base-content/65">
                Be the first to start the conversation.
              </p>
            </div>

            <article
              :for={{id, message} <- @streams.messages}
              id={id}
              class="rounded-2xl border border-base-300 bg-base-200/40 px-4 py-3"
            >
              <header class="flex items-baseline justify-between gap-4">
                <p class="font-medium">{message.user.username}</p>
                <time class="shrink-0 text-xs text-base-content/55" datetime={message.sent_at}>
                  {Calendar.strftime(message.sent_at, "%b %-d, %Y %H:%M UTC")}
                </time>
              </header>
              <p class="mt-1 whitespace-pre-wrap break-words text-sm leading-6">{message.body}</p>
            </article>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    session_token = session["session_token"]
    current_user = Users.get_user_by_session_token(session_token)

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(ChatTakehome.PubSub, Presence.chat_room_topic())

        if session_token do
          {:ok, _ref} = Presence.track(self(), Presence.chat_room_topic(), session_token, %{})
        end

        socket
      else
        socket
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Chat")
     |> stream(:messages, Chat.list_messages())}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end
end
