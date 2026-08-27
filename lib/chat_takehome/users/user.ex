defmodule ChatTakehome.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :username, :string
    field :session_token, :string
    has_many :messages, ChatTakehome.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> update_change(:username, &String.trim/1)
    |> validate_required([:username])
    |> validate_length(:username, min: 1, max: 50)
    |> put_change(:session_token, Ecto.UUID.generate())
    |> validate_required([:session_token])
    |> validate_length(:session_token, min: 1)
    |> unique_constraint(:username, name: :unique_lowercase_username)
    |> unique_constraint(:session_token, name: :unique_session_token)
  end
end
