defmodule ChatTakehome.Repo.Migrations.AddUniqueUsernameConstraint do
  use Ecto.Migration

  def change do
    execute(
      "CREATE UNIQUE INDEX unique_lowercase_username ON users (LOWER(username))",
      "DROP INDEX IF EXISTS unique_lowercase_username"
    )
  end
end
