defmodule ChatTakehomeWeb.UserLiveTest do
  use ChatTakehomeWeb.ConnCase

  import Phoenix.LiveViewTest
  import ChatTakehome.UsersFixtures

  @invalid_attrs %{username: ""}
  defp create_user(_) do
    user = user_fixture()

    %{user: user}
  end

  describe "Index" do
    setup [:create_user]

    test "lists all users", %{conn: conn, user: user} do
      {:ok, index_live, html} = live(conn, ~p"/home")

      assert html =~ "Listing Users"
      assert html =~ user.username
      assert has_element?(index_live, "#user-status-#{user.id}", "Offline")
    end

    test "validates the new-user form", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/home")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Join Chat")
               |> render_click()
               |> follow_redirect(conn, ~p"/users/new")

      assert render(form_live) =~ "New User"

      assert form_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert has_element?(form_live, "#user-form[action='/users'][method='post']")
    end

    test "deletes user in listing", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/home")

      assert index_live |> element("#users-#{user.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#users-#{user.id}")
    end
  end
end
