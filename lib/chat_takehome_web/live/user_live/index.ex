defmodule ChatTakehomeWeb.UserLive.Index do
  use ChatTakehomeWeb, :live_view

  alias ChatTakehome.Users

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
    {:ok,
     socket
     |> assign(:page_title, "Listing Users")
     |> stream(:users, list_users())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Users.get_user!(id)
    {:ok, _} = Users.delete_user(user)

    {:noreply, stream_delete(socket, :users, user)}
  end

  defp list_users do
    Users.list_users()
  end
end
