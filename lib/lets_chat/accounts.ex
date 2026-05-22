defmodule LetsChat.Accounts do
  use Ash.Domain,
    otp_app: :lets_chat

  resources do
    resource LetsChat.Accounts.Token
    resource LetsChat.Accounts.User
  end
end
