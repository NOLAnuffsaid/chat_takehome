defmodule ChatTakehomeWeb.ChatRoomLive do
  use ChatTakehomeWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main id="chat-room">
        <h1>Chat</h1>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Chat")}
  end
end
