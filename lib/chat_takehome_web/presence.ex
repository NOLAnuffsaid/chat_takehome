defmodule ChatTakehomeWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_takehome,
    pubsub_server: ChatTakehome.PubSub
end
