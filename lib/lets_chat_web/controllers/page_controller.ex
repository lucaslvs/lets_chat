defmodule LetsChatWeb.PageController do
  use LetsChatWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
