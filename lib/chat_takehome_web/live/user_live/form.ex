defmodule ChatTakehomeWeb.UserLive.Form do
  use ChatTakehomeWeb, :live_view

  alias ChatTakehome.Users
  alias ChatTakehome.Users.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage user records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="user-form" action={~p"/users"} method="post" phx-change="validate">
        <.input field={@form[:username]} type="text" label="Username" />
        <footer>
          <.button phx-disable-with="Joining Chat..." variant="primary">Join Chat</.button>
          <.button navigate={return_path(@return_to, @user)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Users.get_user!(id)

    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, user)
    |> assign(:form, to_form(Users.change_user(user)))
  end

  defp apply_action(socket, :new, _params) do
    user = %User{}

    socket
    |> assign(:page_title, "New User")
    |> assign(:user, user)
    |> assign(:form, to_form(Users.change_user(user)))
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Users.change_user(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  defp return_path("index", _user), do: ~p"/home"
end
