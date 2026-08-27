defmodule ChatTakehome.UsersTest do
  use ChatTakehome.DataCase

  alias ChatTakehome.Users

  describe "users" do
    alias ChatTakehome.Users.User

    import ChatTakehome.UsersFixtures

    @invalid_attrs %{username: ""}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert user in Users.list_users()
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Users.get_user!(user.id) == user
    end

    test "get_user_by_session_token/1 returns the matching user" do
      user = user_fixture()

      assert Users.get_user_by_session_token(user.session_token) == user
      assert Users.get_user_by_session_token("missing-token") == nil
    end

    test "list_users_by_session_tokens/1 returns matching users" do
      user = user_fixture()

      assert Users.list_users_by_session_tokens([user.session_token]) == [user]
      assert Users.list_users_by_session_tokens([]) == []
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{username: "some username"}

      assert {:ok, %User{} = user} = Users.create_user(valid_attrs)
      assert user.username == "some username"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_user(@invalid_attrs)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Users.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Users.change_user(user)
    end
  end
end
