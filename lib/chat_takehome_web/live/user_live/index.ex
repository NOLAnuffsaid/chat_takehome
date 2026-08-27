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
          <.button variant="primary" navigate={~p"/users/new"}>
            Join Chat
          </.button>
        </:actions>
      </.header>

      <.table
        id="users"
        rows={@streams.users}
      >
        <:col :let={{_id, user}} label="Username">{user.username}</:col>
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
end
