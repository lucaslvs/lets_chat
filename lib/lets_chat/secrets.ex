defmodule LetsChat.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        LetsChat.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:lets_chat, :token_signing_secret)
  end
end
