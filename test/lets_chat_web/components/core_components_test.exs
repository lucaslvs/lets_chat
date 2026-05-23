defmodule LetsChatWeb.CoreComponentsTest do
  use LetsChatWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LetsChatWeb.CoreComponents

  # 8.9 — Single-word name produces one initial
  test "avatar_initials/1 returns single uppercase letter for a one-word name" do
    assert CoreComponents.avatar_initials("Alice") == "A"
  end

  # 8.10 — Multi-word name produces two initials (first and last word)
  test "avatar_initials/1 returns two uppercase letters for a multi-word name" do
    assert CoreComponents.avatar_initials("Alice Smith") == "AS"
  end

  test "avatar_initials/1 uses first and last word for names with 3+ words" do
    assert CoreComponents.avatar_initials("Maria da Silva") == "MS"
  end

  test "avatar_initials/1 handles empty string" do
    assert CoreComponents.avatar_initials("") == ""
  end

  # 8.11 — Same name always yields same color
  test "avatar_color/1 returns the same DaisyUI color token for the same name across multiple calls" do
    color1 = CoreComponents.avatar_color("Alice")
    color2 = CoreComponents.avatar_color("Alice")
    color3 = CoreComponents.avatar_color("Alice")
    assert color1 == color2
    assert color2 == color3
  end

  test "avatar_color/1 returns a valid DaisyUI color token" do
    valid_tokens = ["primary", "secondary", "accent", "info", "success", "warning", "error"]
    assert CoreComponents.avatar_color("Alice") in valid_tokens
  end

  # 8.12 — Gravatar URL is used as avatar src when provided
  test "avatar/1 component renders an img tag when src is provided" do
    assigns = %{}

    html =
      rendered_to_string(~H|<CoreComponents.avatar name="Alice" src="https://gravatar.com/avatar/abc123" />|)

    assert html =~ "<img"
    assert html =~ "https://gravatar.com/avatar/abc123"
  end

  test "avatar/1 component renders initials div when src is nil" do
    assigns = %{}
    html = rendered_to_string(~H|<CoreComponents.avatar name="Alice" />|)

    refute html =~ "<img"
    assert html =~ "A"
  end
end
