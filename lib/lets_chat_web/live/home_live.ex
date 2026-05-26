defmodule LetsChatWeb.HomeLive do
  @moduledoc false
  use LetsChatWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    return_to =
      case params do
        %{"return_to" => return_to} -> validate_return_to(return_to)
        _ -> "/rooms"
      end

    current_user = socket.assigns[:current_user]
    guest_name = session["guest_name"]

    if current_user || guest_name do
      {:ok, push_navigate(socket, to: return_to)}
    else
      guest_session_id = session["guest_session_id"] || Ecto.UUID.generate()

      {:ok,
       assign(socket,
         return_to: return_to,
         error: nil,
         guest_session_id: guest_session_id
       )}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, assign(socket, error: nil)}
  end

  def handle_event("submit", %{"name" => name}, socket) do
    trimmed = String.trim(name)

    if trimmed == "" do
      {:noreply, assign(socket, :error, "Nome não pode ficar em branco")}
    else
      query = [
        name: trimmed,
        return_to: socket.assigns.return_to,
        guest_session_id: socket.assigns.guest_session_id
      ]

      {:noreply, redirect(socket, to: ~p"/session/guest?#{query}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.vue
      v-component="GuestOnboarding"
      return_to={@return_to}
      guest_session_id={@guest_session_id}
      error={@error}
    />
    """
  end

  defp validate_return_to(return_to) do
    if URI.parse(return_to).host, do: "/rooms", else: return_to
  end
end
