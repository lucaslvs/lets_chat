defmodule LetsChatWeb.GuestSessionController do
  use LetsChatWeb, :controller

  def create(conn, %{"name" => name} = params) do
    return_to = validate_return_to(Map.get(params, "return_to", "/rooms"))
    session_id = params["guest_session_id"] || Ecto.UUID.generate()

    conn
    |> put_session("guest_session_id", session_id)
    |> put_session("guest_name", name)
    |> redirect(to: return_to)
  end

  defp validate_return_to(return_to) do
    if URI.parse(return_to).host, do: "/rooms", else: return_to
  end
end
