defmodule ChatTakehome.Chat do
  @moduledoc """
  The chat context.
  """

  import Ecto.Query, warn: false

  alias ChatTakehome.Chat.Message
  alias ChatTakehome.Repo
  alias ChatTakehome.Users.User

  @doc """
  Lists all chat messages in chronological order with their authors.
  """
  def list_messages do
    Message
    |> order_by([message], asc: message.sent_at, asc: message.id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Creates a message attributed to the given user.
  """
  def create_message(%User{} = user, attrs) do
    %Message{user_id: user.id, sent_at: DateTime.utc_now() |> DateTime.truncate(:second)}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> preload_message_user()
  end

  @doc """
  Returns a changeset for tracking message changes.
  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  defp preload_message_user({:ok, message}), do: {:ok, Repo.preload(message, :user)}
  defp preload_message_user({:error, changeset}), do: {:error, changeset}
end
