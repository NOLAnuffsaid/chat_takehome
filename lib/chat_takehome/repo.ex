defmodule ChatTakehome.Repo do
  use Ecto.Repo,
    otp_app: :chat_takehome,
    adapter: Ecto.Adapters.Postgres
end
