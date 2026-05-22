defmodule LetsChatWeb.ErrorJSONTest do
  use LetsChatWeb.ConnCase, async: true

  test "renders 404" do
    assert LetsChatWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert LetsChatWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
