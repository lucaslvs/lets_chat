defmodule LetsChatWeb.HomeLiveTest do
  use LetsChatWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # Helper for test 8.5 — simulates an authenticated user via on_mount before HomeLive.mount/3
  defmodule HomeLiveWithCurrentUser do
    @moduledoc false
    use Phoenix.LiveView

    on_mount {__MODULE__, :assign_current_user}

    def on_mount(:assign_current_user, _params, _session, socket) do
      {:cont, Phoenix.Component.assign(socket, :current_user, %{id: "fake-user-id"})}
    end

    @impl true
    def render(assigns), do: LetsChatWeb.HomeLive.render(assigns)

    @impl true
    def mount(params, session, socket), do: LetsChatWeb.HomeLive.mount(params, session, socket)

    @impl true
    def handle_event(event, params, socket), do: LetsChatWeb.HomeLive.handle_event(event, params, socket)
  end

  # 8.1 — renders the onboarding form for a new unauthenticated visitor
  test "renders the onboarding form for a new unauthenticated visitor", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Explorar salas"
    assert html =~ ~s(phx-submit="submit")
  end

  # 8.2 — submitting a valid name writes guest_session_id and guest_name to session and redirects to /rooms
  test "submitting a valid name writes guest_name to session and redirects to /rooms",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    {:error, {:redirect, %{to: redirect_to}}} =
      view |> element("form") |> render_submit(%{name: "Alice"})

    conn = get(conn, redirect_to)
    assert redirected_to(conn) == "/rooms"
    assert get_session(conn, "guest_name") == "Alice"
  end

  # 8.3 — submitting a valid name with return_to redirects to the return_to path
  test "submitting a valid name with return_to redirects to the return_to path", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/?return_to=/rooms/lobby")

    {:error, {:redirect, %{to: redirect_to}}} =
      view |> element("form") |> render_submit(%{name: "Alice"})

    conn = get(conn, redirect_to)
    assert redirected_to(conn) == "/rooms/lobby"
  end

  # 8.4 — submitting a blank or whitespace-only name shows a validation error
  test "submitting a blank name shows a validation error and does not redirect", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = view |> element("form") |> render_submit(%{name: ""})

    assert html =~ "Nome não pode ficar em branco"
  end

  test "submitting a whitespace-only name shows a validation error", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = view |> element("form") |> render_submit(%{name: "   "})

    assert html =~ "Nome não pode ficar em branco"
  end

  # 8.5 — authenticated user is redirected past onboarding
  test "authenticated user visiting / is redirected to /rooms without seeing the form",
       %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/rooms"}}} =
             live_isolated(conn, HomeLiveWithCurrentUser)
  end

  # 8.6 — returning guest with guest_name in session is redirected to /rooms
  test "returning guest with guest_name in session is redirected to /rooms", %{conn: conn} do
    conn = init_test_session(conn, %{"guest_name" => "Alice"})

    assert {:error, {:live_redirect, %{to: "/rooms"}}} = live(conn, "/")
  end

  # 8.7 — guest_session_id is generated in mount and written to session via GuestSessionController
  test "guest_session_id is written to session after form submission", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    {:error, {:redirect, %{to: redirect_to}}} =
      view |> element("form") |> render_submit(%{name: "Alice"})

    conn = get(conn, redirect_to)
    assert get_session(conn, "guest_session_id")
  end

  test "guest_session_id is not regenerated when already present in session", %{conn: conn} do
    existing_id = Ecto.UUID.generate()
    conn = init_test_session(conn, %{"guest_session_id" => existing_id})

    {:ok, view, _html} = live(conn, "/")

    {:error, {:redirect, %{to: redirect_to}}} =
      view |> element("form") |> render_submit(%{name: "Alice"})

    conn = get(conn, redirect_to)
    assert get_session(conn, "guest_session_id") == existing_id
  end

  # 8.8 — avatar preview changes on phx-change validate event when name is typed
  test "avatar preview changes on phx-change validate event when name is typed", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render_change(view, "validate", %{name: "Alice"})

    assert html =~ "A"
  end

  # 8.16 — validate_return_to/1 rejects a return_to value containing a host component
  test "return_to with a host component falls back to /rooms on submit", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/?return_to=https://evil.com")

    {:error, {:redirect, %{to: redirect_to}}} =
      view |> element("form") |> render_submit(%{name: "Alice"})

    conn = get(conn, redirect_to)
    assert redirected_to(conn) == "/rooms"
  end
end
