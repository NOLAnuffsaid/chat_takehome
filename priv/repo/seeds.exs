alias ChatTakehome.Repo
alias ChatTakehome.Users
alias ChatTakehome.Users.User

for username <- ["Ada Lovelace", "Grace Hopper", "Linus Torvalds", "Margaret Hamilton"] do
  case Repo.get_by(User, username: username) do
    nil ->
      {:ok, _user} = Users.create_user(%{username: username})

    _user ->
      :ok
  end
end
