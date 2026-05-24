defmodule LetsChat.Chat do
  @moduledoc false
  use Ash.Domain,
    otp_app: :lets_chat

  resources do
    resource LetsChat.Chat.Room
  end
end
