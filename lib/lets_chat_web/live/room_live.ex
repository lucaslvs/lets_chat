defmodule LetsChatWeb.RoomLive do
  @moduledoc false
  use LetsChatWeb, :live_view

  alias LetsChat.Chat.Room

  on_mount {LetsChatWeb.LiveUserAuth, :require_guest_name}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, room: nil)}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    case Room
         |> Ash.Query.for_read(:get_by_slug, %{slug: slug})
         |> Ash.read_one(authorize?: false) do
      {:ok, %Room{} = room} ->
        {:noreply, assign(socket, room: room)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Sala não encontrada.")
         |> push_navigate(to: ~p"/rooms")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.vue
      v-component="RoomShell"
      room={@room}
    />
    """
  end
end
