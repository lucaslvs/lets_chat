defmodule LetsChatWeb.LobbyLiveTest do
  use LetsChatWeb.ConnCase, async: true

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
    {:ok, _view, html} = live(auth_conn(conn), "/rooms")
    assert html =~ "Nenhuma sala criada ainda"
    refute html =~ "Criar a primeira sala"
  end

  # 8.8 — Rooms listed in reverse chronological order
  test "lists rooms newest first", %{conn: conn} do
    import Ecto.Query, only: [from: 2]

    room1 = create_room!("First Room")

    # inserted_at is writable? false so Ash defers to DB now(), which returns the
    # transaction start time (same for all rows in the sandbox transaction).
    # Pin room1 to a known past timestamp so room2 is definitively newer.
    # UUID must be dumped to binary for raw-table queries without a schema.
    {:ok, id_bin} = Ecto.UUID.dump(room1.id)

    LetsChat.Repo.update_all(
      from(r in "rooms", where: r.id == ^id_bin),
      set: [inserted_at: ~U[2020-01-01 00:00:00Z]]
    )

    room2 = create_room!("Second Room")

    {:ok, _view, html} = live(auth_conn(conn), "/rooms")

    pos1 = html |> :binary.match(room1.name) |> elem(0)
    pos2 = html |> :binary.match(room2.name) |> elem(0)

    assert pos2 < pos1
  end

  # 8.10 — Each card shows name, slug, relative timestamp
  test "room cards show name, slug, and relative timestamp", %{conn: conn} do
    room = create_room!("Chat Room")

    {:ok, _view, html} = live(auth_conn(conn), "/rooms")

    assert html =~ room.name
    assert html =~ room.slug
    assert html =~ "agora mesmo"
  end

  # 8.11 — New room button opens modal without page navigation
  test "clicking New Room button opens creation modal", %{conn: conn} do
    create_room!("Existing Room")
    {:ok, view, html} = live(auth_conn(conn), "/rooms")

    refute html =~ "create_room"

    html = view |> element("button[phx-click='open_modal']", "Nova sala") |> render_click()

    assert html =~ "create_room"
  end

  # 8.12 — Deep-link to /rooms?new=true opens modal on mount
  test "navigating to /rooms?new=true opens modal on initial render", %{conn: conn} do
    {:ok, _view, html} = live(auth_conn(conn), "/rooms?new=true")
    assert html =~ "create_room"
    assert html =~ "Criar sala"
  end

  # 8.13 — Slug preview updates as user types
  test "typing room name updates slug preview", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    html = render_change(view, "validate", %{"room" => %{"name" => "My Room"}})

    assert html =~ "my-room"
  end

  # 8.14 — Available slug shows positive feedback
  test "available slug shows disponivel indicator", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    html = render_change(view, "validate", %{"room" => %{"name" => "Unique Room xyz987"}})

    assert html =~ "disponível"
  end

  # 8.15 — Taken slug shows negative feedback and disables submit button
  test "taken slug shows ja em uso indicator and disables submit button", %{conn: conn} do
    create_room!("Taken Room")
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    html = render_change(view, "validate", %{"room" => %{"name" => "Taken Room"}})

    assert html =~ "em uso"
    assert html =~ ~r/<button[^>]+disabled[^>]*>\s*Criar sala/
  end

  # 8.16 — Availability check uses base slug only (no numeric suffix)
  test "availability check uses base slug without suffix", %{conn: conn} do
    create_room!("Test Room")
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")

    html = render_change(view, "validate", %{"room" => %{"name" => "Test Room"}})

    assert html =~ "em uso"
  end

  # Clicking outside modal closes it
  test "clicking outside the modal box closes the modal", %{conn: conn} do
    {:ok, view, _html} = live(auth_conn(conn), "/rooms?new=true")
    assert render(view) =~ "create_room"

    view |> element("div.modal[phx-click='close_modal']") |> render_click()

    refute render(view) =~ "create_room"
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
      view
      |> element("form[phx-submit='create_room']")
      |> render_submit(%{"room" => %{"name" => "My Brand New Room"}})

    assert path =~ "/rooms/"
    assert path =~ "my-brand-new-room"
  end
end
