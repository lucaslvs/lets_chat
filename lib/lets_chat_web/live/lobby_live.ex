defmodule LetsChatWeb.LobbyLive do
  @moduledoc false
  use LetsChatWeb, :live_view

  alias LetsChat.Chat.Room

  on_mount {LetsChatWeb.LiveUserAuth, :require_guest_name}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :clear_flash, 5_000)

    {:ok,
     assign(socket,
       rooms: [],
       show_modal: false,
       form: nil,
       slug_preview: nil,
       slug_available: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    rooms =
      Room
      |> Ash.Query.for_read(:list)
      |> Ash.read!(authorize?: false)

    show_modal = Map.get(params, "new") == "true"
    form = if show_modal, do: new_form()

    {:noreply,
     assign(socket,
       rooms: rooms,
       show_modal: show_modal,
       form: form,
       slug_preview: nil,
       slug_available: nil
     )}
  end

  @impl true
  def handle_event("open_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: true,
       form: new_form(),
       slug_preview: nil,
       slug_available: nil
     )}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: false,
       form: nil,
       slug_preview: nil,
       slug_available: nil
     )}
  end

  def handle_event("validate", params, socket) do
    inner = Map.get(params, "room", %{})
    name = Map.get(inner, "name", "")

    slug_preview =
      case Slug.slugify(name) do
        "" -> nil
        nil -> nil
        slug -> slug
      end

    slug_available =
      if slug_preview, do: slug_available?(slug_preview)

    form =
      if socket.assigns.form do
        socket.assigns.form |> AshPhoenix.Form.validate(inner) |> to_form()
      end

    {:noreply, assign(socket, form: form, slug_preview: slug_preview, slug_available: slug_available)}
  end

  def handle_event("create_room", params, socket) do
    inner = Map.get(params, "room", %{})

    case AshPhoenix.Form.submit(socket.assigns.form, params: inner) do
      {:ok, room} ->
        {:noreply, push_navigate(socket, to: ~p"/rooms/#{room.slug}")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp new_form do
    Room
    |> AshPhoenix.Form.for_create(:create, domain: LetsChat.Chat, as: "room")
    |> to_form()
  end

  defp slug_available?(slug) do
    not Ash.exists?(
      Ash.Query.filter_input(Room, %{slug: slug}),
      authorize?: false
    )
  end

  defp time_ago(dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      diff < 60 -> "agora mesmo"
      diff < 3600 -> "#{div(diff, 60)} min atrás"
      diff < 86_400 -> "#{div(diff, 3600)}h atrás"
      true -> "#{div(diff, 86_400)} dias atrás"
    end
  end
end
