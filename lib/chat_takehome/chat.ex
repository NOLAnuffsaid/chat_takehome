defmodule ChatTakehome.Chat do
  @moduledoc """
  The chat context.
  """

  import Ecto.Query, warn: false

  alias ChatTakehome.Chat.Message
  alias ChatTakehome.Repo
  alias ChatTakehome.Users.User

  @message_page_size 50

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
  Lists the newest page of messages in chronological order.
  """
  def list_message_page(opts \\ []) do
    page_size = page_limit(opts)

    page_size
    |> newest_messages_query()
    |> fetch_message_page(page_size)
  end

  @doc """
  Lists a page of messages older than the given message in chronological order.
  """
  def list_message_page_before(%Message{} = message, opts \\ []) do
    page_size = page_limit(opts)

    page_size
    |> older_messages_query(message)
    |> fetch_message_page(page_size)
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

  defp page_limit(opts) do
    Keyword.get(opts, :limit, @message_page_size)
  end

  defp newest_messages_query(limit) do
    Message
    |> newest_first()
    |> limit(^(limit + 1))
  end

  defp older_messages_query(limit, message) do
    Message
    |> where(
      [candidate],
      candidate.sent_at < ^message.sent_at or
        (candidate.sent_at == ^message.sent_at and candidate.id < ^message.id)
    )
    |> newest_first()
    |> limit(^(limit + 1))
  end

  defp newest_first(query) do
    query
    |> order_by([message], desc: message.sent_at, desc: message.id)
    |> preload(:user)
  end

  defp fetch_message_page(query, page_size) do
    messages = Repo.all(query)
    has_more_messages? = length(messages) > page_size

    messages =
      messages
      |> Enum.take(page_size)
      |> Enum.reverse()

    {messages, has_more_messages?}
  end
end
