defmodule LetsChatWeb.LobbyLiveTest do
  use LetsChatWeb.ConnCase, async: true

  import LiveVue.Test, only: [get_vue: 2]
  import Phoenix.LiveViewTest

  defp auth_conn(conn) do
    init_test_session(conn, %{"guest_name" => "Test User", "guest_session_id" => "test-uuid"})
  end

  defp create_room!(name) do
    Ash.create!(LetsChat.Chat.Room, %{name: name}, authorize?: false)
  end

  # 8.22 — Unauthenticated access to lobby is blocked
  test "unauthenticated access to /rooms redirects to home with return_to", %{conn: conn} do
    {:error, {:redirect, %{to: path}}} = live(conn, "/rooms")
    assert String.starts_with?(path, "/")
    assert path =~ "return_to"
    assert path =~ "rooms"
  end

  # 8.24 — Authenticated guest can access lobby
  test "authenticated guest can access /rooms without redirection", %{conn: conn} do
    {:ok, _view, _html} = live(auth_conn(conn), "/rooms")
  end

  # 8.9 — Empty state shown when no rooms exist
  test "shows empty state message when no rooms exist", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms")

    vue = get_vue(view, name: "RoomLobby")
    assert vue.props["rooms"] == []
  end

  # 8.8 — Rooms listed in reverse chronological order
  test "lists rooms newest first", %{conn: conn} do
    import Ecto.Query, only: [from: 2]

    room1 = create_room!("First Room")

    {:ok, id_bin} = Ecto.UUID.dump(room1.id)

    LetsChat.Repo.update_all(
      from(r in "rooms", where: r.id == ^id_bin),
      set: [inserted_at: ~U[2020-01-01 00:00:00Z]]
    )

    room2 = create_room!("Second Room")

    {:ok, view, _html} = live(auth_conn(conn), "/rooms")

    vue = get_vue(view, name: "RoomLobby")
    rooms = vue.props["rooms"]

    names = Enum.map(rooms, & &1["name"])
    assert Enum.at(names, 0) == room2.name
    assert Enum.at(names, 1) == room1.name
  end

  # 8.10 — Each card shows name, slug, relative timestamp (via props)
  test "room cards show name, slug in Vue props", %{conn: conn} do
    room = create_room!("Chat Room")

    {:ok, view, _html} = live(auth_conn(conn), "/rooms")

    vue = get_vue(view, name: "RoomLobby")
    assert Enum.any?(vue.props["rooms"], fn r -> r["name"] == room.name end)
    assert Enum.any?(vue.props["rooms"], fn r -> r["slug"] == room.slug end)
  end

  # 8.11 — New room button opens modal
  test "clicking New Room button opens creation modal", %{conn: conn} do
    create_room!("Existing Room")
    {:ok, view, _html} = live(auth_conn(conn), "/rooms")

    vue = get_vue(view, name: "RoomLobby")
    refute vue.props["show_modal"]

    render_click(view, "open_modal", %{})

    vue = get_vue(view, name: "RoomLobby")
    assert vue.props["show_modal"] == true
  end

  # 8.12 — Deep-link to /rooms?new=true opens modal on mount
  test "navigating to /rooms?new=true opens modal on initial render", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    vue = get_vue(view, name: "RoomLobby")
    assert vue.props["show_modal"] == true
    assert vue.props["form"]
  end

  # 8.13 — Slug preview is now Vue-side computed; server emits push_event for availability
  test "typing room name emits slug_availability push_event", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    render_change(view, "validate", %{"room" => %{"name" => "My Room"}})

    assert_push_event(view, "slug_availability", %{available: _})
  end

  # 8.14 — Available slug emits push_event with available: true
  test "available slug emits slug_availability with available true", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    render_change(view, "validate", %{"room" => %{"name" => "Unique Room xyz987"}})

    assert_push_event(view, "slug_availability", %{available: true})
  end

  # 8.15 — Taken slug emits push_event with available: false
  test "taken slug emits slug_availability with available false", %{conn: conn} do
    create_room!("Taken Room")
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    render_change(view, "validate", %{"room" => %{"name" => "Taken Room"}})

    assert_push_event(view, "slug_availability", %{available: false})
  end

  # 8.16 — Availability check uses base slug only (no numeric suffix)
  test "availability check uses base slug without suffix", %{conn: conn} do
    create_room!("Test Room")
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    render_change(view, "validate", %{"room" => %{"name" => "Test Room"}})

    assert_push_event(view, "slug_availability", %{available: false})
  end

  # Clicking outside modal closes it
  test "clicking outside the modal box closes the modal", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    vue = get_vue(view, name: "RoomLobby")
    assert vue.props["show_modal"] == true

    render_click(view, "close_modal", %{})

    vue = get_vue(view, name: "RoomLobby")
    refute vue.props["show_modal"]
  end

  # 8.25 — Flash error renders and auto-dismisses via :clear_flash
  test "shows flash error message when present in socket", %{conn: conn} do
    conn = conn |> auth_conn() |> fetch_flash() |> put_flash(:error, "Sala não encontrada.")
    {:ok, _view, html} = live(conn, "/rooms")
    assert html =~ "Sala não encontrada"
  end

  test "flash is cleared after :clear_flash message", %{conn: conn} do
    conn = conn |> auth_conn() |> fetch_flash() |> put_flash(:error, "Sala não encontrada.")
    {:ok, view, html} = live(conn, "/rooms")
    assert html =~ "Sala não encontrada"

    send(view.pid, :clear_flash)
    refute render(view) =~ "Sala não encontrada"
  end

  # 8.17 — Successful creation redirects to /rooms/:slug
  test "successful room creation redirects to the new room", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    {:error, {:live_redirect, %{to: path}}} =
      render_submit(view, "create_room", %{"room" => %{"name" => "My Brand New Room"}})

    assert path =~ "/rooms/"
    assert path =~ "my-brand-new-room"
  end
end
