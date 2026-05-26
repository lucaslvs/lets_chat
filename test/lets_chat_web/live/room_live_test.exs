defmodule LetsChatWeb.RoomLiveTest do
  use LetsChatWeb.ConnCase, async: true

  import LiveVue.Test, only: [get_vue: 2]
  import Phoenix.LiveViewTest

  defp auth_conn(conn) do
    init_test_session(conn, %{"guest_name" => "Test User", "guest_session_id" => "test-uuid"})
  end

  defp create_room!(name \\ "Test Room") do
    Ash.create!(LetsChat.Chat.Room, %{name: name}, authorize?: false)
  end

  # 8.23 — Unauthenticated access to room shell is blocked
  test "unauthenticated access to /rooms/:slug redirects to home with return_to", %{conn: conn} do
    room = create_room!()
    {:error, {:redirect, %{to: path}}} = live(conn, "/rooms/#{room.slug}")
    assert path =~ "return_to"
    assert path =~ "rooms"
  end

  # 8.18 — Room header displays correct room name
  test "room header displays correct room name", %{conn: conn} do
    room = create_room!("My Chat Room")
    {:ok, view, _html} = live(auth_conn(conn), "/rooms/#{room.slug}")
    vue = get_vue(view, name: "RoomShell")
    assert vue.props["room"]["name"] == room.name
  end

  # 8.20 — Unknown slug redirects to lobby with flash error
  test "unknown slug redirects to /rooms with error flash", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/rooms", flash: flash}}} =
             live(auth_conn(conn), "/rooms/this-slug-does-not-exist-99999")

    assert flash["error"] =~ "Sala não encontrada"
  end

  # 8.21 — Back to lobby link navigates to /rooms
  test "back to lobby link is present and points to /rooms", %{conn: conn} do
    room = create_room!()
    {:ok, view, _html} = live(auth_conn(conn), "/rooms/#{room.slug}")
    vue = get_vue(view, name: "RoomShell")
    assert vue.component == "RoomShell"
    assert vue.props["room"]["slug"] == room.slug
  end
end
