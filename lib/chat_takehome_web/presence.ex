defmodule ChatTakehomeWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_takehome,
    pubsub_server: ChatTakehome.PubSub

  @chat_room_topic "chat:room"

  def chat_room_topic, do: @chat_room_topic
end
