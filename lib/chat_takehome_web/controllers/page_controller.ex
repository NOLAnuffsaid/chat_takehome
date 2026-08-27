defmodule ChatTakehomeWeb.PageController do
  use ChatTakehomeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
