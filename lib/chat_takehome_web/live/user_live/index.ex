defmodule ChatTakehomeWeb.UserLive.Index do
  use ChatTakehomeWeb, :live_view

  alias ChatTakehome.Users
  alias ChatTakehomeWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Users
        <:actions>
          <.button :if={@current_user} id="rejoin-chat" variant="primary" navigate={~p"/chat"}>
            Rejoin Chat
          </.button>
          <.button
            :if={is_nil(@current_user)}
            id="join-chat"
            variant="primary"
            navigate={~p"/users/new"}
          >
            Join Chat
          </.button>
        </:actions>
      </.header>

      <.table
        id="users"
        rows={@streams.users}
      >
        <:col :let={{_id, user}} label="Username">
          <span class="inline-flex items-center gap-2">
            <.icon
              name={status_icon(user, @online_session_tokens)}
              class={[
                "size-4 shrink-0",
                if(online?(user, @online_session_tokens),
                  do: "text-success",
                  else: "text-base-content/35"
                )
              ]}
            />
            <span>{user.username}</span>
            <span id={"user-status-#{user.id}"} class="sr-only">
              {status_label(user, @online_session_tokens)}
            </span>
          </span>
        </:col>
        <:action :let={{id, user}}>
          <.link
            phx-click={JS.push("delete", value: %{id: user.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(ChatTakehome.PubSub, Presence.chat_room_topic())
        socket
      else
        socket
      end

    {:ok,
     socket
     |> assign(:page_title, "Listing Users")
     |> assign(:online_session_tokens, online_session_tokens())
     |> stream(:users, list_users())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Users.get_user!(id)
    {:ok, _} = Users.delete_user(user)

    {:noreply, stream_delete(socket, :users, user)}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    users = list_users()

    {:noreply,
     socket
     |> assign(:online_session_tokens, online_session_tokens())
     |> stream(:users, users, reset: true)}
  end

  defp list_users do
    Users.list_users()
  end

  defp online_session_tokens do
    Presence.chat_room_topic()
    |> Presence.list()
    |> Map.keys()
    |> MapSet.new()
  end

  defp online?(user, online_session_tokens) do
    MapSet.member?(online_session_tokens, user.session_token)
  end

  defp status_icon(user, online_session_tokens) do
    if online?(user, online_session_tokens), do: "hero-check-circle", else: "hero-minus-circle"
  end

  defp status_label(user, online_session_tokens) do
    if online?(user, online_session_tokens), do: "Online", else: "Offline"
  end
end
