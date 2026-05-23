defmodule LetsChatWeb.LiveUserAuthTest do
  use LetsChatWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defmodule GuardedLive do
    @moduledoc false
    use Phoenix.LiveView

    on_mount {LetsChatWeb.LiveUserAuth, :require_guest_name}

    @impl true
    def render(assigns), do: ~H"<div>Protected content</div>"

    @impl true
    def mount(_params, _session, socket), do: {:ok, socket}
  end

  defmodule GuardedLiveWithUser do
    @moduledoc false
    use Phoenix.LiveView

    on_mount {__MODULE__, :assign_current_user}
    on_mount {LetsChatWeb.LiveUserAuth, :require_guest_name}

    def on_mount(:assign_current_user, _params, _session, socket) do
      {:cont, Phoenix.Component.assign(socket, :current_user, %{email: "test@example.com"})}
    end

    @impl true
    def render(assigns), do: ~H"<div>Protected with user</div>"

    @impl true
    def mount(_params, _session, socket), do: {:ok, socket}
  end

  # 8.13 — require_guest_name halts and redirects to /?return_to=<path> when no identity
  test "require_guest_name halts and redirects when no identity is present", %{conn: conn} do
    assert {:error, {:redirect, %{to: redirect_to}}} = live_isolated(conn, GuardedLive)

    assert redirect_to =~ "/?return_to="
  end

  # 8.14 — require_guest_name allows access when guest_name is present in session
  test "require_guest_name allows access when guest_name is present in session", %{conn: conn} do
    conn = init_test_session(conn, %{"guest_name" => "Alice"})
    {:ok, _view, html} = live_isolated(conn, GuardedLive)

    assert html =~ "Protected content"
  end

  # 8.15 — require_guest_name allows access when current_user is present
  test "require_guest_name allows access when current_user is present, regardless of guest_name",
       %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, GuardedLiveWithUser)

    assert html =~ "Protected with user"
  end
end
