defmodule ChatTakehomeWeb.ChatRoomLive do
  use ChatTakehomeWeb, :live_view

  alias ChatTakehome.Chat
  alias ChatTakehome.Chat.Message
  alias ChatTakehome.Users
  alias ChatTakehome.Users.User
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

          <div
            :if={@has_more_messages?}
            class="border-b border-base-300 px-6 py-3 text-center sm:px-8"
          >
            <button
              id="load-earlier-messages"
              type="button"
              phx-click="load_earlier_messages"
              phx-disable-with="Loading earlier messages..."
              class="text-sm font-medium text-primary transition hover:text-primary/80"
            >
              Load earlier messages
            </button>
          </div>

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

          <div :if={@current_user} class="border-t border-base-300 bg-base-200/30 px-6 py-5 sm:px-8">
            <.form
              for={@form}
              id="message-form"
              phx-change="validate_message"
              phx-submit="send_message"
            >
              <div class="flex items-end gap-3">
                <div class="min-w-0 flex-1">
                  <.input
                    field={@form[:body]}
                    type="text"
                    label="Message"
                    placeholder="Write a message..."
                    autocomplete="off"
                  />
                </div>
                <.button id="send-message" phx-disable-with="Sending..." variant="primary">
                  <.icon name="hero-paper-airplane" class="size-4" /> Send
                </.button>
              </div>
            </.form>
          </div>

          <div
            :if={is_nil(@current_user)}
            id="message-sign-in-required"
            class="border-t border-base-300 px-6 py-5 sm:px-8"
          >
            <p class="text-sm text-base-content/60">Join the chat to send a message.</p>
          </div>

          <aside id="online-users" class="border-t border-base-300 bg-base-200/30 px-6 py-5 sm:px-8">
            <div class="flex items-center justify-between gap-4">
              <div>
                <p class="text-sm font-semibold">Online now</p>
                <p class="text-xs text-base-content/60">{length(@online_users)} in the room</p>
              </div>
              <.icon name="hero-user-group" class="size-5 text-base-content/50" />
            </div>

            <p
              :if={@online_users == []}
              id="online-users-empty"
              class="mt-4 text-sm text-base-content/60"
            >
              No one is online yet.
            </p>

            <ul
              :if={@online_users != []}
              id="online-users-list"
              class="mt-4 grid gap-2 sm:grid-cols-2"
            >
              <li
                :for={user <- @online_users}
                id={"online-user-#{user.id}"}
                class="flex items-center gap-2 text-sm"
              >
                <.icon name="hero-check-circle" class="size-4 shrink-0 text-success" />
                <span>{user.username}</span>
                <span class="sr-only">Online</span>
              </li>
            </ul>
          </aside>
        </section>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    {messages, has_more_messages?} = Chat.list_message_page()

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(ChatTakehome.PubSub, Presence.chat_room_topic())

        {:ok, _ref} =
          Presence.track(self(), Presence.chat_room_topic(), current_user.session_token, %{})

        socket
      else
        socket
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:online_users, online_users())
     |> assign(:page_title, "Chat")
     |> assign(:form, new_message_form())
     |> assign(:has_more_messages?, has_more_messages?)
     |> assign(:oldest_message, List.first(messages))
     |> stream(:messages, messages)}
  end

  @impl true
  def handle_event("validate_message", %{"message" => message_params}, socket) do
    changeset = Chat.change_message(%Message{}, message_params)

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event(
        "send_message",
        %{"message" => message_params},
        %{assigns: %{current_user: %User{} = user}} = socket
      ) do
    case Chat.create_message(user, message_params) do
      {:ok, message} ->
        Phoenix.PubSub.broadcast(
          ChatTakehome.PubSub,
          Presence.chat_room_topic(),
          {:message_created, message}
        )

        {:noreply, assign(socket, :form, new_message_form())}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("send_message", _params, socket) do
    {:noreply, put_flash(socket, :error, "Join the chat before sending a message.")}
  end

  def handle_event("load_earlier_messages", _params, socket) do
    case socket.assigns.oldest_message do
      nil ->
        {:noreply, assign(socket, :has_more_messages?, false)}

      oldest_message ->
        {messages, has_more_messages?} = Chat.list_message_page_before(oldest_message)

        {:noreply,
         socket
         |> assign(:has_more_messages?, has_more_messages?)
         |> assign(:oldest_message, List.first(messages) || oldest_message)
         |> stream(:messages, messages, at: 0)}
    end
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    oldest_message = socket.assigns.oldest_message || message

    {:noreply,
     socket
     |> assign(:oldest_message, oldest_message)
     |> stream_insert(:messages, message)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_users, online_users())}
  end

  defp new_message_form do
    %Message{}
    |> Chat.change_message()
    |> to_form()
  end

  defp online_users do
    Presence.chat_room_topic()
    |> Presence.list()
    |> Map.keys()
    |> Users.list_users_by_session_tokens()
  end
end
