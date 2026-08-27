defmodule ChatTakehome.ChatTest do
  use ChatTakehome.DataCase

  alias ChatTakehome.Chat
  alias ChatTakehome.Chat.Message
  alias ChatTakehome.Repo

  import ChatTakehome.UsersFixtures

  describe "messages" do
    test "creates a trimmed message with an author and sent time" do
      user = user_fixture()

      assert {:ok, %Message{} = message} = Chat.create_message(user, %{body: " Hello, chat! "})
      assert message.body == "Hello, chat!"
      assert message.user_id == user.id
      assert %DateTime{} = message.sent_at
    end

    test "rejects a blank message" do
      user = user_fixture()

      assert {:error, changeset} = Chat.create_message(user, %{body: "   "})
      assert "can't be blank" in errors_on(changeset).body
    end

    test "lists messages with their authors" do
      user = user_fixture()
      {:ok, message} = Chat.create_message(user, %{body: "A saved message"})

      assert Enum.any?(Chat.list_messages(), fn listed_message ->
               listed_message.id == message.id and listed_message.user == user
             end)
    end

    test "paginates messages in chronological order" do
      user = user_fixture()

      messages =
        for {body, offset} <- [{"First", 0}, {"Second", 1}, {"Third", 2}] do
          {:ok, message} = Chat.create_message(user, %{body: body})

          Repo.update!(
            Ecto.Changeset.change(message,
              sent_at: DateTime.add(~U[2099-01-01 00:00:00Z], offset)
            )
          )
        end

      {[second, third], true} = Chat.list_message_page(limit: 2)
      assert [second.id, third.id] == [Enum.at(messages, 1).id, Enum.at(messages, 2).id]

      {older_messages, _has_more_messages?} = Chat.list_message_page_before(second, limit: 2)

      assert Enum.any?(older_messages, fn message ->
               message.id == Enum.at(messages, 0).id
             end)
    end
  end
end
