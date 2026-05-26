defmodule LetsChatWeb.LobbyLive do
  @moduledoc false
  use LetsChatWeb, :live_view

  alias LetsChat.Chat.Room
  alias Phoenix.HTML.Form

  on_mount {LetsChatWeb.LiveUserAuth, :require_guest_name}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :clear_flash, 5_000)

    {:ok,
     assign(socket,
       rooms: [],
       show_modal: false,
       form: new_form()
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    rooms =
      Room
      |> Ash.Query.for_read(:list)
      |> Ash.read!(authorize?: false)

    show_modal = Map.get(params, "new") == "true"
    form = new_form()

    {:noreply,
     assign(socket,
       rooms: rooms,
       show_modal: show_modal,
       form: form
     )}
  end

  @impl true
  def handle_event("open_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: true,
       form: new_form()
     )}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: false,
       form: new_form()
     )}
  end

  def handle_event("validate", params, socket) do
    inner = Map.get(params, "room", %{})
    name = Map.get(inner, "name", "")

    slug =
      case Slug.slugify(name) do
        "" -> nil
        nil -> nil
        s -> s
      end

    available = if slug, do: slug_available?(slug)

    form = socket.assigns.form |> AshPhoenix.Form.validate(inner) |> normalize_form()

    socket =
      if slug do
        push_event(socket, "slug_availability", %{available: available})
      else
        socket
      end

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create_room", params, socket) do
    inner = Map.get(params, "room", %{})

    case AshPhoenix.Form.submit(socket.assigns.form, params: inner) do
      {:ok, room} ->
        {:reply, %{reset: true}, push_navigate(socket, to: ~p"/rooms/#{room.slug}")}

      {:error, form} ->
        {:noreply, assign(socket, form: normalize_form(form))}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp new_form do
    Room
    |> AshPhoenix.Form.for_create(:create, domain: LetsChat.Chat, as: "room")
    |> normalize_form()
  end

  # LiveVue.Encoder for Phoenix.HTML.Form calls Map.merge(form.data, ...) which crashes
  # when form.data is nil (AshPhoenix create forms have no pre-existing record).
  defp normalize_form(%Form{} = form) do
    %{form | data: form.data || %{}}
  end

  defp normalize_form(ash_form) do
    ash_form |> to_form() |> normalize_form()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} />
    <.flash kind={:error} flash={@flash} />
    <.vue
      v-component="RoomLobby"
      rooms={@rooms}
      form={@form}
      show_modal={@show_modal}
    />
    """
  end

  defp slug_available?(slug) do
    not Ash.exists?(
      Ash.Query.filter_input(Room, %{slug: slug}),
      authorize?: false
    )
  end
end
