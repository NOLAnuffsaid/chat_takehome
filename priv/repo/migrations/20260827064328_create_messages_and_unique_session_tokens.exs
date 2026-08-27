defmodule ChatTakehome.Repo.Migrations.CreateMessagesAndUniqueSessionTokens do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:session_token], name: :unique_session_token)

    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :text, null: false
      add :sent_at, :utc_datetime, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:user_id])
    create index(:messages, [:sent_at])
  end
end
