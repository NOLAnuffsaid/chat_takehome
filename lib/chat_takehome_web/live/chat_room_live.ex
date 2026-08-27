defmodule ChatTakehomeWeb.ChatRoomLive do
  use ChatTakehomeWeb, :live_view

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

          <div class="flex min-h-80 flex-col items-center justify-center px-6 py-16 text-center sm:px-8">
            <div class="mb-5 flex size-16 items-center justify-center rounded-full bg-primary/10 text-primary">
              <.icon name="hero-chat-bubble-oval-left-ellipsis" class="size-8" />
            </div>
            <h2 class="text-lg font-semibold">The room is ready</h2>
            <p class="mt-2 max-w-sm text-sm leading-6 text-base-content/65">
              Messages and online participants will appear here as the chat grows.
            </p>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, %{"session_token" => session_token}, socket) do
    current_user = Users.get_user_by_session_token(session_token)

    socket =
      if connected?(socket) do
        {:ok, _ref} = Presence.track(self(), Presence.chat_room_topic(), session_token, %{})
        socket
      else
        socket
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Chat")}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_user, nil)
     |> assign(:page_title, "Chat")}
  end
end
