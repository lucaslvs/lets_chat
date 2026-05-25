defmodule LetsChat.Chat.RoomTest do
  use LetsChat.DataCase, async: true

  alias Ash.Resource.Info
  alias LetsChat.Chat.Room

  # 8.1 — Room is created with valid name
  test "creates a room with valid name" do
    room = Ash.create!(Room, %{name: "Test Room"}, authorize?: false)
    assert room.name == "Test Room"
    assert room.slug == "test-room"
    assert room.id
  end

  # 8.2 — Slug uniqueness collision appends numeric suffix
  test "slug collision appends numeric suffix" do
    room1 = Ash.create!(Room, %{name: "Elixir Study Group"}, authorize?: false)
    room2 = Ash.create!(Room, %{name: "Elixir Study Group"}, authorize?: false)

    assert room1.slug == "elixir-study-group"
    assert room2.slug == "elixir-study-group-2"
  end

  # 8.3 — Room visibility defaults to :public
  test "visibility defaults to :public" do
    room = Ash.create!(Room, %{name: "Test Room"}, authorize?: false)
    assert room.visibility == :public
  end

  # 8.4 — owner_user_id is stored as nil without error
  test "owner_user_id can be nil" do
    room = Ash.create!(Room, %{name: "Test Room"}, authorize?: false)
    assert is_nil(room.owner_user_id)
  end

  # 8.5 — Basic slug generation from "Elixir Study Group!"
  test "slugifies special characters and spaces" do
    room = Ash.create!(Room, %{name: "Elixir Study Group!"}, authorize?: false)
    assert room.slug == "elixir-study-group"
  end

  # 8.6 — No update action allows changing slug
  test "no update actions are defined on Room" do
    update_actions =
      Room
      |> Info.actions()
      |> Enum.filter(fn action -> action.type == :update end)

    assert update_actions == []
  end

  # 8.7 — Domain is registered and Room is reachable
  test "LetsChat.Chat is registered in ash_domains" do
    ash_domains = Application.get_env(:lets_chat, :ash_domains, [])
    assert LetsChat.Chat in ash_domains
  end

  test "Room is reachable via LetsChat.Chat domain" do
    assert {:ok, _rooms} = Ash.read(Room, authorize?: false)
  end
end
