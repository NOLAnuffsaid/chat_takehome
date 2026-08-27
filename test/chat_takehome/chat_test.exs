defmodule ChatTakehome.ChatTest do
  use ChatTakehome.DataCase

  alias ChatTakehome.Chat
  alias ChatTakehome.Chat.Message

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
  end
end
