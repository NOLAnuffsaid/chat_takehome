defmodule ChatTakehomeWeb.HomeController do
  use ChatTakehomeWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: ~p"/home")
  end
end
